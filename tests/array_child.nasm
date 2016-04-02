%include 'inc/func.inc'

;;;;;;;;;;;
; test code
;;;;;;;;;;;

	fn_function tests/array_child

		;read exit command etc
		static_call sys_mail, mymail
		static_call sys_mem, free

		;wait a bit
		vp_cpy 1000000, r0
		fn_call sys/math_random
		vp_add 1000000, r0
		static_call sys_task, sleep

		;print Hello and return
		fn_debug_str 'Hello from array worker !'
		vp_ret

	fn_function_end
