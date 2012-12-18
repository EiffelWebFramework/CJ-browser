note
	description: "Summary description for {CJ_HEADER_TOOL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	CJ_HEADER_TOOL

inherit
	CJ_TOOL

create
	make

feature {NONE} -- Initialization

	create_interface_objects
		local
			vb: EV_VERTICAL_BOX
		do
			create vb
			create grid
			vb.extend (grid)
			vb.set_border_width (3)
			widget := vb
			initialize_grid (grid)
		end

	initialize_grid (g: like grid)
		local
			lab: EV_GRID_LABEL_ITEM
		do
			g.set_column_count_to (2)
			g.column (1).set_title ("Header name")
			g.column (2).set_title ("value")
			g.enable_row_separators
			g.enable_column_separators

			g.set_row_count_to (1)
			create lab.make_with_text ("...")
			g.set_item (1, 1, lab)
			lab.pointer_button_press_actions.force_extend (agent
				local
					n: INTEGER
				do
					n := grid.row_count
					add_new_row (Void)
					if attached grid.row (n) as l_row then
						l_row.ensure_visible
						l_row.enable_select
					end
				end
			)

			add_new_row ("Authorization")
		end

	add_new_row (a_name: detachable READABLE_STRING_GENERAL)
		require
			grid.row_count > 0
		local
			g: like grid
			edit: EV_GRID_EDITABLE_ITEM
--			lab: EV_GRID_LABEL_ITEM
			n: INTEGER
		do
			g := grid
			n := g.row_count
			g.insert_new_row (n)

			if a_name /= Void then
				g.set_item (1, n, create {EV_GRID_LABEL_ITEM}.make_with_text (a_name))
			else
				create edit
				g.set_item (1, n, edit)
				edit.pointer_button_release_actions.force_extend (agent edit.activate)
			end
			if a_name /= Void and then a_name.as_lower.is_equal ("authorization") then
				create edit
				g.set_item (2, n, edit)
				edit.set_tooltip ("Click to edit. Right Click to add basic authorization ...")
				edit.pointer_double_press_actions.extend (agent (gi: EV_GRID_EDITABLE_ITEM; x: INTEGER; y: INTEGER; button: INTEGER; x_tilt: DOUBLE; y_tilt: DOUBLE; pressure: DOUBLE; screen_x: INTEGER; screen_y: INTEGER)
					do
						if button = 1 then
							gi.activate
						end
					end (edit, ?,?,?,?,?,?,?,?))
				edit.pointer_button_release_actions.extend (agent (gi: EV_GRID_EDITABLE_ITEM; x: INTEGER; y: INTEGER; button: INTEGER; x_tilt: DOUBLE; y_tilt: DOUBLE; pressure: DOUBLE; screen_x: INTEGER; screen_y: INTEGER)
					local
						s: STRING_32
					do
						if button = 3 then
							create s.make_empty
							get_basic_auth (s)
							gi.set_text (s)
						end
					end (edit, ?,?,?,?,?,?,?,?))
			else
				create edit
				g.set_item (2, n, edit)
				edit.pointer_double_press_actions.force_extend (agent edit.activate)
			end
		end

feature -- Access

	header: HTTP_HEADER
		local
			r, n: INTEGER
			k,v: STRING_32
		do
			create Result.make
			if attached grid as g then
				from
					r := 1
					n := g.row_count
				until
					r > n
				loop
					if attached g.row (r) as l_row then
						if
							attached {EV_GRID_LABEL_ITEM} l_row.item (1) as lab_k and
							attached {EV_GRID_LABEL_ITEM} l_row.item (2) as lab_v
						then
							k := lab_k.text
							v := lab_v.text
							if k.is_valid_as_string_8 and v.is_valid_as_string_8 then
								Result.put_header_key_value (k.to_string_8, v.to_string_8)
							end
						end
					end
					r := r + 1
				end
			end
		end

feature -- Event

	get_basic_auth (buf: STRING_32)
		local
			dlg: EV_DIALOG
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			tf_login: EV_TEXT_FIELD
			tf_passwd: EV_PASSWORD_FIELD
			but: EV_BUTTON
			lab: EV_LABEL
		do
			create dlg.make_with_title ("HTTP_AUTHORIZATION: basic auth")
			create vb
			vb.set_border_width (3)
			vb.set_padding_width (3)
			dlg.extend (vb)

			create hb; hb.set_padding_width (3); vb.extend (hb); vb.disable_item_expand (hb)
			create lab.make_with_text ("Username")
			create tf_login
			hb.extend (lab); hb.disable_item_expand (lab)
			hb.extend (tf_login)

			create hb; hb.set_padding_width (3); vb.extend (hb); vb.disable_item_expand (hb)
			create lab.make_with_text ("Password")
			create tf_passwd
			hb.extend (lab); hb.disable_item_expand (lab)
			hb.extend (tf_passwd)

			create hb; hb.set_padding_width (3); vb.extend (hb); vb.disable_item_expand (hb)

			create but.make_with_text ("Apply")
			but.select_actions.extend (agent (ia_buf: STRING_32; ia_tf_u, ia_tf_p: EV_TEXT_FIELD)
					local
						h: HTTP_AUTHORIZATION
					do
						ia_buf.wipe_out
						create h.make_basic_auth (ia_tf_u.text, ia_tf_p.text)
						if attached h.http_authorization as s then
							ia_buf.append_string_general (s)
						end
					end (buf, tf_login, tf_passwd))
			but.select_actions.extend (agent dlg.destroy)
			hb.extend (but)
			create but.make_with_text_and_action ("Cancel", agent dlg.destroy)
			hb.extend (but)

			dlg.set_width (200)

			dlg.show
		end

feature -- Access

	title: STRING_32 = "Header"

feature -- Widget	

	grid: EV_GRID

	widget: EV_WIDGET

invariant
	widget_attached: widget /= Void

end
