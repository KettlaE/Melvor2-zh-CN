extends Node
# Melvor Idle 2 简体中文翻译 - 运行时文字替换
#
# 覆盖层做法与本脚本结构，以 bmlee9527 / YukoCat 的繁体中文社区包为参考：
#   https://github.com/bmlee9527/melvor-idle-2-zh-tw
#   Steam 指南：https://steamcommunity.com/sharedfiles/filedetails/?id=3841417206
# 感谢他们公开了 Godot override.cfg + 松散 PO + 运行时 GDScript 这条安装路径。
# 本文件已改为语系 zh_CN、简体用词，并补上复数 msgstr[1] 样板与时间单位二次替换；
# 译文内容来自我们自己的简体中文包，不是繁体社区包的译文。
#
# 游戏有些文字是程序直接显示原文、没有经过翻译系统，翻译文件管不到。
# 这个脚本在每次画面绘制前检查 Label / RichTextLabel / Button 的文字，
# 能在翻译文件里找到对应中文的就换掉，并处理数字样板、时间单位、逗号列表等格式。
# 只在游戏语言设为简体中文（zh_CN）时动作；切回英文时，把改过的文字还原成原文。

# 设成 true 会把仍是英文的文字记到 user://zh_CN_untranslated.txt，方便补翻译
# Windows 实际路径：%APPDATA%\Games By Malcs\Melvor Idle 2\zh_CN_untranslated.txt
const LOG_UNTRANSLATED := false
const LOG_PATH := "user://zh_CN_untranslated.txt"
const PO_NAME := "zh_CN.po"
# 调试用：记录每段英文文字的节点类型与替换结果
const DEBUG := false
const DEBUG_PATH := "user://zh_CN_debug.txt"
const CACHE_LIMIT := 20000

const UNITS := {
	"day": "天", "days": "天",
	"hour": "小时", "hours": "小时",
	"minute": "分钟", "minutes": "分钟",
	"second": "秒", "seconds": "秒",
}
# 中英混合的句子里直接替换的片语
const PHRASES := {
	"less than ": "不到 ",
}

# 每帧检查全部约 1,800 个控件太花时间，所以分三种：
# 新出现的下一帧立刻处理；被游戏改回英文过的（计时器等）每帧检查；其余轮流检查，每帧 1/8
const COLD_SLICES := 8
var _nodes := {}      # instance_id -> Control
var _fresh := []      # 刚出现、还没检查过的 instance_id
var _cold := []       # 轮流检查的 instance_id
var _cold_pos := 0
var _hot := {}        # 每帧检查的 instance_id
var _sets := {}       # instance_id -> 被脚本改写的次数
var _last := {}       # instance_id -> 上次看到（或写入）的文字
var _orig := {}       # instance_id -> 被改写前的英文，切回英文时还原用
var _popups := {}     # 弹出菜单 instance_id -> PopupMenu
var _popup_orig := {} # 弹出菜单 instance_id -> {选项索引: 英文}
var _active := false  # 目前游戏语言是不是简体中文
var _cache := {}      # 原文 -> 替换结果
var _seen := {}
var _templates := {}  # 关键字 -> [{re, tokens, dst}]
var _rich := {}       # 去掉 BBCode 的原文 -> 带 BBCode 的译文
var _unit_re := RegEx.new()
var _latin_re := RegEx.new()
var _word_re := RegEx.new()
var _run_re := RegEx.new()
var _tag_re := RegEx.new()
var _cjk_re := RegEx.new()
var _ph_re := RegEx.new()
var _log: FileAccess
var _dbg: FileAccess
var _dbg_seen := {}
var _dbg_usec := 0
var _dbg_frames := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_unit_re.compile("(\\d+(?:[.,]\\d+)?) ?(days?|hours?|minutes?|seconds?)\\b")
	_latin_re.compile("[A-Za-z]{3,}")
	_word_re.compile("[A-Za-z]{3,}")
	_run_re.compile("[A-Za-z][A-Za-z']*(?: [A-Za-z][A-Za-z']*)*")
	_tag_re.compile("\\[img[^\\]]*\\][^\\[]*\\[/img\\]|\\[[^\\]]*\\]")
	_cjk_re.compile("[\\x{4e00}-\\x{9fff}]")
	_ph_re.compile("\\{[^{}]+\\}")
	_load_templates()
	if LOG_UNTRANSLATED:
		_log = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if DEBUG:
		_dbg = FileAccess.open(DEBUG_PATH, FileAccess.WRITE)
	get_tree().node_added.connect(_track)
	_track_tree(get_tree().root)
	# 排在所有节点的 _process 之后执行：游戏每帧重设文字后立刻换掉，
	# 重绘排程还来得及在同一帧画出中文（frame_pre_draw 太晚，会一直显示英文）
	process_priority = 1 << 30


func _is_zh_cn() -> bool:
	# 只在简体中文时动作，避免与繁体包或其他 zh_* 语系互相干扰
	var loc := TranslationServer.get_locale().replace("-", "_")
	return loc == "zh_CN" or loc.begins_with("zh_CN_")


func _process(_delta: float) -> void:
	var zh := _is_zh_cn()
	if zh != _active:
		_active = zh
		if zh:
			# 刚切到中文：全部重新检查
			_last.clear()
			_fresh.append_array(_cold)
			_cold.clear()
		else:
			_restore_all()
	if not _active:
		return
	_refresh_popups()
	if not DEBUG:
		_refresh()
		return
	var t0 := Time.get_ticks_usec()
	_refresh()
	_dbg_usec += Time.get_ticks_usec() - t0
	_dbg_frames += 1
	if _dbg_frames == 600 and _dbg:
		_dbg.store_line("#perf %d nodes (%d hot), %.3f ms/frame, %d fps" % [_nodes.size(), _hot.size(), _dbg_usec / 600000.0, Engine.get_frames_per_second()])
		_dbg.flush()
		_dbg_frames = 0
		_dbg_usec = 0


# 切回英文：仍显示脚本写入文字的控件改回原文；游戏自己翻译的部分由游戏重绘
func _restore_all() -> void:
	for id in _orig.keys():
		var n = _nodes.get(id)
		if n == null or not is_instance_valid(n):
			continue
		var cur: String = n.text
		if n is RichTextLabel and cur == "":
			cur = n.get_parsed_text()
		var o: String = _orig[id]
		if n is RichTextLabel and n.text == "":
			n.clear()
			n.append_text(o)
		elif cur == _last.get(id, ""):
			n.text = o
	for pid in _popup_orig.keys():
		var p = instance_from_id(pid)
		if p is PopupMenu:
			for i in _popup_orig[pid]:
				if i < p.item_count:
					p.set_item_text(i, _popup_orig[pid][i])
	_orig.clear()
	_popup_orig.clear()
	_last.clear()
	_hot.clear()
	_sets.clear()


func _track_tree(n: Node) -> void:
	_track(n)
	for c in n.get_children():
		_track_tree(c)


func _track(n: Node) -> void:
	if n is Label or n is RichTextLabel or n is Button:
		var id := n.get_instance_id()
		if not _nodes.has(id):
			_nodes[id] = n
			_fresh.append(id)
	elif n is PopupMenu:
		# 弹出菜单的选项不是文字控件（例如左下角的追踪时段「1 hour」），打开时才翻译
		_popups[n.get_instance_id()] = n


# 游戏可能在打开菜单的同时才填入选项，所以每帧检查开着的菜单（数量很少）
func _refresh_popups() -> void:
	for id in _popups.keys():
		var p = _popups[id]
		if not is_instance_valid(p):
			_popups.erase(id)
			_popup_orig.erase(id)
		elif p.visible:
			_translate_popup(p)


func _translate_popup(p: PopupMenu) -> void:
	var id := p.get_instance_id()
	var orig: Dictionary = _popup_orig.get(id, {})
	for i in p.item_count:
		var s := p.get_item_text(i)
		var t := _convert(s)
		if t != s:
			if not _cjk_re.search(s):
				orig[i] = s
			p.set_item_text(i, t)
	if not orig.is_empty():
		_popup_orig[id] = orig


func _refresh() -> void:
	for id in _fresh:
		_check(id)
	_cold.append_array(_fresh)
	_fresh.clear()
	for id in _hot.keys():
		_check(id)
	var batch := ceili(_cold.size() / float(COLD_SLICES))
	for i in batch:
		if _cold.is_empty():
			break
		if _cold_pos >= _cold.size():
			_cold_pos = 0
		if _check(_cold[_cold_pos]):
			_cold_pos += 1
		else:
			_cold.remove_at(_cold_pos)


# 检查并替换一个控件的文字；控件已被释放时回传 false
func _check(id: int) -> bool:
	var n = _nodes.get(id)
	if n == null or not is_instance_valid(n):
		_nodes.erase(id)
		_last.erase(id)
		_orig.erase(id)
		_hot.erase(id)
		_sets.erase(id)
		return false
	var s: String = n.text
	# 游戏用 add_text() 等方法拼出来的富文本，text 属性是空的，要读解析后的文字
	var built := false
	if s == "":
		if not (n is RichTextLabel) or not n.is_visible_in_tree():
			return true
		built = true
		s = n.get_parsed_text()
	if s == _last.get(id, ""):
		return true
	# 先比对文字（便宜），有变才检查是否可见；隐藏的控件等显示出来再处理
	if not built and not n.is_visible_in_tree():
		return true
	var t := s
	if built and _rich.has(s.strip_edges()):
		# 商店说明等：解析后的文字没有标签，对不上翻译文件，改用去掉标签的原文比对，译文保留标签
		t = _rich[s.strip_edges()]
	# 其他拼出来的富文本只能整段重写，会失去原本的图标和颜色，所以只处理不含中文的短句
	elif not built or (s.length() < 100 and not _cjk_re.search(s)):
		t = _convert(s)
	if DEBUG and _dbg and not _dbg_seen.has(s) and _latin_re.search(s):
		_dbg_seen[s] = true
		_dbg.store_line("%s|%s|%s|%s => %s" % [n.get_class(), n.can_auto_translate(), built, s.c_escape(), t.c_escape()])
		_dbg.flush()
	if t != s:
		if not _cjk_re.search(s):
			_orig[id] = s
		if built:
			n.clear()
			n.append_text(t)
		else:
			n.text = t
		# 改写过又被游戏改回去，代表它会一直更新，之后每帧检查
		var c: int = _sets.get(id, 0) + 1
		_sets[id] = c
		if c >= 2:
			_hot[id] = true
	_last[id] = t
	return true


func _convert(s: String) -> String:
	var key := s
	if _cache.has(key):
		return _cache[key]
	var t := _translate(s)
	if _cache.size() > CACHE_LIMIT:
		_cache.clear()
	_cache[key] = t
	if LOG_UNTRANSLATED and _log and t == s and _tr(s) == s and not _seen.has(s) and _latin_re.search(s):
		_seen[s] = true
		_log.store_line(s.c_escape())
		_log.flush()
	return t


func _translate(s: String) -> String:
	if s.is_empty() or not _latin_re.search(s):
		return s
	# 整句在翻译文件里
	# 有些节点标示会自动翻译、画面上却仍是英文，所以一律直接换成中文
	var t := _tr(s)
	if t != s:
		return _apply_units(t)
	# 前后有空白的情况
	var core := s.strip_edges()
	if core != s and _tr(core) != core:
		return _apply_units(s.replace(core, _tr(core)))
	# 「Stab, Slash, Crush」这类逗号列表：每一项都有翻译才换
	if ", " in s:
		var parts := s.split(", ")
		var out := PackedStringArray()
		for p in parts:
			var tp := _tr(p.strip_edges())
			if tp == p.strip_edges():
				out.clear()
				break
			out.append(tp)
		if out.size() == parts.size():
			return "、".join(out)
	# 翻译文件里带 {0} 的样板：「5 Available」对上「{0:N0} Available」
	t = _match_template(s)
	if t != s:
		return _apply_units(t)
	# 短的英文词组逐字翻译：「Normal Resistance」→「普通抗性」，每个字都有翻译才换
	if not _cjk_re.search(s) and s.count(" ") < 4 and _run_re.search(s) and _run_re.search(s).get_string() == s:
		var words := PackedStringArray()
		for w in s.split(" "):
			var tw := _tr(w)
			if tw == w:
				words.clear()
				break
			words.append(tw)
		if not words.is_empty():
			return "".join(words)
	var result := s
	# 中文句子里夹着的英文名称：「…后 Rune Essence 耗尽」
	if _cjk_re.search(s):
		result = _replace_runs(result)
		for p in PHRASES:
			result = result.replace(p, PHRASES[p])
	# 时间单位：「10 minutes」→「10 分钟」
	return _apply_units(result)


func _apply_units(s: String) -> String:
	var result := s
	for m in _unit_re.search_all(result):
		result = result.replace(m.get_string(), m.get_string(1) + " " + UNITS[m.get_string(2)])
	return result


func _tr(s: String) -> String:
	return String(TranslationServer.translate(s))


func _match_template(s: String) -> String:
	var tried := {}
	for wm in _word_re.search_all(s):
		var w := wm.get_string().to_lower()
		if tried.has(w) or not _templates.has(w):
			continue
		tried[w] = true
		for tpl in _templates[w]:
			var m: RegExMatch = tpl.re.search(s)
			if m == null:
				continue
			var out: String = tpl.dst
			var ok := true
			for i in tpl.tokens.size():
				var v := m.get_string(i + 1)
				var tv := _tr(v)
				# 「Level {0}」不该吃下整句「Level up your …」：占位符抓到没翻译的英文句子就不算符合
				if tv == v and v.count(" ") >= 2 and _latin_re.search(v):
					ok = false
					break
				out = out.replace(tpl.tokens[i], tv)
			if ok:
				return out
	return s


# 只替换 BBCode 标签以外的部分，避免动到图片路径
func _replace_runs(s: String) -> String:
	var out := ""
	var pos := 0
	for m in _tag_re.search_all(s):
		out += _replace_runs_plain(s.substr(pos, m.get_start() - pos)) + m.get_string()
		pos = m.get_end()
	return out + _replace_runs_plain(s.substr(pos))


func _replace_runs_plain(s: String) -> String:
	var out := s
	for m in _run_re.search_all(s):
		var w := m.get_string()
		var t := _tr(w)
		if t != w:
			out = out.replace(w, t)
	return out


# 从翻译文件读出含 {…} 占位符的条目，转成正则表达式样板
func _load_templates() -> void:
	# Windows 版的翻译文件在游戏文件夹的 mod 里；若有人参考繁体包的 Mac 做法，也会试 user://
	var f: FileAccess = null
	for p in [OS.get_executable_path().get_base_dir().path_join("mod").path_join(PO_NAME),
			"res://mod/" + PO_NAME, "user://" + PO_NAME]:
		f = FileAccess.open(p, FileAccess.READ)
		if f != null:
			break
	if f == null:
		return
	var cur := {}
	var field := ""
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with("msgid_plural "):
			field = "msgid_plural"
			cur[field] = _unquote(line.substr(13))
		elif line.begins_with("msgid "):
			_add_template(cur)
			cur = {}
			field = "msgid"
			cur[field] = _unquote(line.substr(6))
		elif line.begins_with("msgstr[0] "):
			field = "msgstr"
			cur[field] = _unquote(line.substr(10))
		elif line.begins_with("msgstr[1] "):
			# 保留复数译文，供 msgid_plural 样板使用（目标进度 Current / Max 等）
			field = "msgstr1"
			cur[field] = _unquote(line.substr(10))
		elif line.begins_with("msgstr "):
			field = "msgstr"
			cur[field] = _unquote(line.substr(7))
		elif line.begins_with("\"") and field != "":
			cur[field] += _unquote(line)
		else:
			field = ""
	_add_template(cur)


func _unquote(q: String) -> String:
	return q.substr(1, q.length() - 2).c_unescape()


func _add_template(e: Dictionary) -> void:
	if not e.has("msgid") or e.get("msgstr", "") == "":
		return
	_build_template(e.msgid, e.msgstr)
	if "[" in e.msgid and not "{" in e.msgid:
		_rich[_tag_re.sub(e.msgid, "", true).strip_edges()] = e.msgstr
	if e.has("msgid_plural"):
		var pdst: String = e.get("msgstr1", "")
		if pdst == "":
			pdst = e.get("msgstr", "")
		if pdst != "":
			_build_template(e.msgid_plural, pdst)
			if "[" in e.msgid_plural and not "{" in e.msgid_plural:
				_rich[_tag_re.sub(e.msgid_plural, "", true).strip_edges()] = pdst


func _build_template(src: String, dst: String) -> void:
	if src.length() > 150 or not "{" in src:
		return
	var pattern := "^"
	var tokens := []
	var literal := ""
	var pos := 0
	for m in _ph_re.search_all(src):
		var lit := src.substr(pos, m.get_start() - pos)
		literal += lit + " "
		pattern += _escape(lit) + "(.+?)"
		tokens.append(m.get_string())
		pos = m.get_end()
	if tokens.is_empty():
		return
	var tail := src.substr(pos)
	literal += tail
	pattern += _escape(tail) + "$"
	for m in _ph_re.search_all(dst):
		if not tokens.has(m.get_string()):
			return
	# 用最长的英文字当索引，没有英文字的样板（如「{0}: {1}」）太笼统，不采用
	var key := ""
	for wm in _word_re.search_all(literal):
		if wm.get_string().length() > key.length():
			key = wm.get_string()
	if key == "":
		return
	var re := RegEx.new()
	if re.compile(pattern) != OK:
		return
	key = key.to_lower()
	if not _templates.has(key):
		_templates[key] = []
	_templates[key].append({"re": re, "tokens": tokens, "dst": dst})


func _escape(s: String) -> String:
	var out := ""
	for c in s:
		if c in "\\.^$|?*+()[]{}":
			out += "\\"
		out += c
	return out
