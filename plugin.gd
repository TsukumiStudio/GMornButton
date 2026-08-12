@tool
extends EditorPlugin

## GMornButton を組み込むための入口。
##
## 釦は場面ごとに置くものなので、自動読み込みには登録しない。代わりに
## 「ノードを追加」から選べるようにする。台本を手で貼り付ける手間を省く。

const TYPE_NAME := "GMornButton"

func _script_path() -> String:
	return get_script().resource_path.get_base_dir().path_join("gmorn_button.gd")

func _enter_tree() -> void:
	add_custom_type(TYPE_NAME, "BaseButton", load(_script_path()), null)

func _exit_tree() -> void:
	remove_custom_type(TYPE_NAME)
