%include 'inc/func.inc'
%include 'inc/mail.inc'
%include 'class/class_vector.inc'
%include 'class/class_string.inc'

;;;;;;;;;;;
; test code
;;;;;;;;;;;

	fn_function tests/array

		const num_child, 128

		ptr tasks
		ptr name
		ptr ids
		ptr msg
		ulong cnt

		push_scope

		;vector of tasks
		static_call vector, create, {}, {tasks}
		assign {0}, {cnt}
		loop_while {cnt != num_child}
			static_call string, create_from_cstr, {"tests/array_child"}, {name}
			static_call vector, push_back, {tasks, name}
			assign {cnt + 1}, {cnt}
		loop_end

		;open array
		static_call sys_task, open_array, {tasks}, {ids}

		;send exit messages etc
		assign {0}, {cnt}
		loop_while {cnt != num_child}
			static_call sys_mail, alloc, {}, {msg}
			assign {ids[cnt * id_size].id_mbox}, {msg->msg_dest.id_mbox}
			assign {ids[cnt * id_size].id_cpu}, {msg->msg_dest.id_cpu}
			assign {msg_header_size}, {msg->msg_length}
			static_call sys_mail, send, {msg}
			static_call sys_task, yield
			assign {cnt + 1}, {cnt}
		loop_end

		;free vector and ID array
		static_call vector, deref, {tasks}
		static_call sys_mem, free, {ids}
		pop_scope
		return

	fn_function_end
