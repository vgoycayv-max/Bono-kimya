import os, sqlite3, time
from flask import Flask, request, jsonify, abort

app = Flask(__name__)
ADMIN_KEY = os.environ.get("ADMIN_KEY", "degistir")
os.makedirs("data", exist_ok=True)


def db():
    c = sqlite3.connect("data/db02.sqlite")
    c.row_factory = sqlite3.Row
    return c


with db() as c:
    c.executescript("""
    create table if not exists users(device primary key, name, about, contact);
    create table if not exists pages(id integer primary key autoincrement, title, text, lang,
        category, device, author, status default 'pending', created real);
    create table if not exists likes(page_id, device, primary key(page_id, device));
    create table if not exists saves(page_id, device, primary key(page_id, device));
    create table if not exists comments(id integer primary key autoincrement, page_id, device,
        name, text, status, created real);
    create table if not exists blocked(device primary key);
    create table if not exists settings(k primary key, v);
    insert or ignore into settings values('comment_mode','auto');
    """)


def admin_only():
    if request.headers.get("X-Admin-Key") != ADMIN_KEY:
        abort(403)


def rows(sql, args=()):
    with db() as c:
        return [dict(r) for r in c.execute(sql, args).fetchall()]


def blocked(c, dev):
    return c.execute("select 1 from blocked where device=?", (dev,)).fetchone() is not None


def uname(c, dev):
    r = c.execute("select name from users where device=?", (dev,)).fetchone()
    return r["name"] if r else None


@app.post("/register")
def register():
    d = request.get_json(force=True, silent=True) or {}
    dev = str(d.get("device", ""))[:64]
    name = str(d.get("name", "")).strip()[:40]
    if not dev or not name:
        return "isim gerekli", 400
    with db() as c:
        if blocked(c, dev):
            return "engelli", 403
        c.execute("insert or replace into users values(?,?,?,?)",
                  (dev, name, str(d.get("about", ""))[:300], str(d.get("contact", ""))[:100]))
    return jsonify(ok=True)


@app.post("/submit")
def submit():
    d = request.get_json(force=True, silent=True) or {}
    dev = str(d.get("device", ""))[:64]
    title = str(d.get("title", "")).strip()[:200]
    text = str(d.get("text", "")).strip()[:20000]
    if not title:
        return "baslik gerekli", 400
    with db() as c:
        if blocked(c, dev):
            return "engelli", 403
        name = uname(c, dev)
        if not name:
            return "kayit yok", 400
        c.execute("insert into pages(title,text,lang,category,device,author,created) values(?,?,?,?,?,?,?)",
                  (title, text, str(d.get("lang", ""))[:5], str(d.get("category", ""))[:40], dev, name, time.time()))
    return jsonify(ok=True)


@app.get("/pages")
def pages():
    dev = request.args.get("device", "")
    q = "%" + request.args.get("q", "") + "%"
    sql = """select p.id,p.title,p.text,p.lang,p.category,p.author,
      (select count(*) from likes l where l.page_id=p.id) as likes,
      (select count(*) from comments c where c.page_id=p.id and c.status='approved') as comments,
      (select count(*) from likes l where l.page_id=p.id and l.device=?) as liked,
      (select count(*) from saves s where s.page_id=p.id and s.device=?) as saved
      from pages p where p.status='approved' and (p.title like ? or p.text like ?)"""
    args = [dev, dev, q, q]
    if request.args.get("lang"):
        sql += " and p.lang=?"
        args.append(request.args["lang"])
    if request.args.get("category"):
        sql += " and p.category=?"
        args.append(request.args["category"])
    if request.args.get("saved") == "1":
        sql += " and p.id in (select page_id from saves where device=?)"
        args.append(dev)
    return jsonify(rows(sql + " order by p.id desc limit 200", args))


def toggle(table):
    d = request.get_json(force=True)
    dev, pid = str(d.get("device", "")), int(d["id"])
    with db() as c:
        if blocked(c, dev):
            abort(403)
        if c.execute(f"select 1 from {table} where page_id=? and device=?", (pid, dev)).fetchone():
            c.execute(f"delete from {table} where page_id=? and device=?", (pid, dev))
            on = 0
        else:
            c.execute(f"insert into {table} values(?,?)", (pid, dev))
            on = 1
        n = c.execute(f"select count(*) from {table} where page_id=?", (pid,)).fetchone()[0]
    return jsonify(on=on, count=n)


@app.post("/like")
def like():
    return toggle("likes")


@app.post("/save")
def save():
    return toggle("saves")


@app.get("/comments")
def comments():
    return jsonify(rows("select name,text from comments where page_id=? and status='approved' order by id",
                        (int(request.args.get("id", 0)),)))


@app.post("/comment")
def comment():
    d = request.get_json(force=True, silent=True) or {}
    dev, text = str(d.get("device", "")), str(d.get("text", "")).strip()[:1000]
    if not text:
        return "bos yorum", 400
    with db() as c:
        if blocked(c, dev):
            return "engelli", 403
        name = uname(c, dev)
        if not name:
            return "kayit yok", 400
        mode = c.execute("select v from settings where k='comment_mode'").fetchone()["v"]
        status = "approved" if mode == "auto" else "pending"
        c.execute("insert into comments(page_id,device,name,text,status,created) values(?,?,?,?,?,?)",
                  (int(d["id"]), dev, name, text, status, time.time()))
    return jsonify(status=status)


# ---------- yonetici ----------
@app.get("/admin/pending")
def pending():
    admin_only()
    return jsonify(rows("select id,title,text,author as name,device from pages where status='pending' order by id"))


@app.get("/admin/comments")
def pending_comments():
    admin_only()
    return jsonify(rows("""select c.id, p.title as title, c.text, c.name, c.device from comments c
        join pages p on p.id=c.page_id where c.status='pending' order by c.id"""))


def ids_action(sql_one, sql_all=None):
    d = request.get_json(force=True)
    with db() as c:
        if d.get("all") and sql_all:
            c.execute(sql_all)
        for i in d.get("ids", []):
            c.execute(sql_one, (int(i),))
    return jsonify(ok=True)


@app.post("/admin/approve")
def approve():
    admin_only()
    return ids_action("update pages set status='approved' where id=?",
                      "update pages set status='approved' where status='pending'")


@app.post("/admin/reject")
def reject():
    admin_only()
    return ids_action("delete from pages where id=?")


@app.post("/admin/comment_approve")
def comment_approve():
    admin_only()
    return ids_action("update comments set status='approved' where id=?",
                      "update comments set status='approved' where status='pending'")


@app.post("/admin/comment_reject")
def comment_reject():
    admin_only()
    return ids_action("delete from comments where id=?")


@app.get("/admin/settings")
def get_settings():
    admin_only()
    return jsonify({r["k"]: r["v"] for r in rows("select k,v from settings")})


@app.post("/admin/settings")
def set_settings():
    admin_only()
    d = request.get_json(force=True)
    if d.get("comment_mode") in ("auto", "hold"):
        with db() as c:
            c.execute("update settings set v=? where k='comment_mode'", (d["comment_mode"],))
    return jsonify(ok=True)


@app.post("/admin/edit")
def edit():
    admin_only()
    d = request.get_json(force=True)
    with db() as c:
        c.execute("update pages set title=?, text=?, category=? where id=?",
                  (d["title"], d["text"], d["category"], int(d["id"])))
    return jsonify(ok=True)


@app.post("/admin/block")
def block():
    admin_only()
    d = request.get_json(force=True)
    with db() as c:
        for dev in d.get("devices", []):
            c.execute("insert or ignore into blocked(device) values(?)", (dev,))
            c.execute("delete from pages where device=? and status='pending'", (dev,))
            c.execute("delete from comments where device=? and status='pending'", (dev,))
    return jsonify(ok=True)


@app.post("/admin/unblock")
def unblock():
    admin_only()
    d = request.get_json(force=True)
    with db() as c:
        for dev in d.get("devices", []):
            c.execute("delete from blocked where device=?", (dev,))
    return jsonify(ok=True)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
