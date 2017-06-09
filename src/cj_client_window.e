note
	description : "Objects that ..."
	author      : "$Author$"
	date        : "$Date$"
	revision    : "$Revision$"

class
	CJ_CLIENT_WINDOW

inherit
	ANY
		redefine
			default_create
		end

feature {NONE} -- Initialization

	default_create
		do
			create_interface_objects
			initialize_tools (docking_manager)
			initialize
		end

feature -- Access

	window: EV_TITLED_WINDOW

	main_box: EV_VERTICAL_BOX


feature {NONE} -- Initialization

	create_interface_objects
		local
			win: EV_TITLED_WINDOW
			vb: EV_VERTICAL_BOX
			dm: SD_DOCKING_MANAGER
		do
			create field_url

			create button_go.make_with_text ("Go")
			create button_settings.make_with_text ("...")

			create cj_client_proxy.make (create {CJ_CLIENT}.make (""))

			create win
			create vb
			win.extend (vb)
			window := win
			main_box := vb

			create dm.make (vb, window)
			docking_manager := dm

			cj_client_proxy.context_adaptation_agents.extend (agent updated_context)
		end

	initialize_tools (dm: SD_DOCKING_MANAGER)
		do
			create information_tool.make (cj_client_proxy, dm)
			create queries_tool.make (cj_client_proxy, dm)
			create template_tool.make (cj_client_proxy, dm)
			create formatted_body_tool.make (cj_client_proxy, dm)
			create http_response_tool.make (cj_client_proxy, dm)
			create header_tool.make (cj_client_proxy, dm)
			queries_tool.on_query_actions.extend (agent explore_query)
		end

	initialize
			-- Initialize `Current'.
		local
			vb: EV_VERTICAL_BOX
			hb: EV_HORIZONTAL_BOX
			lab: EV_LABEL
--			nb: EV_NOTEBOOK
			dm: like docking_manager
			f: RAW_FILE
		do
			vb := main_box
			vb.set_border_width (3)

			create hb
			hb.set_padding_width (5)
			hb.set_border_width (3)
			create lab.make_with_text ("Location")
			hb.extend (lab)
			hb.disable_item_expand (lab)
			hb.extend (field_url)
			hb.extend (button_go)
			hb.disable_item_expand (button_go)
			hb.extend (button_settings)
			hb.disable_item_expand (button_settings)


			vb.extend (hb)
			vb.disable_item_expand (hb)

			dm := docking_manager
			create f.make ("layout.db")
			dm.close_editor_place_holder
			initialize_tools (dm)
			dm.contents.extend (information_tool.sd_content)
			dm.contents.extend (queries_tool.sd_content)
			dm.contents.extend (template_tool.sd_content)
			dm.contents.extend (formatted_body_tool.sd_content)
			dm.contents.extend (http_response_tool.sd_content)
			dm.contents.extend (header_tool.sd_content)

			if
				f.exists and then f.is_readable and then
				dm.open_config ("layout.db") -- side effect !!!
			then

			else
				information_tool.sd_content.set_top ({SD_ENUMERATION}.bottom)
				formatted_body_tool.sd_content.set_tab_with (information_tool.sd_content, False)
				http_response_tool.sd_content.set_tab_with (information_tool.sd_content, False)
				queries_tool.sd_content.set_top ({SD_ENUMERATION}.bottom)
				template_tool.sd_content.set_relative (queries_tool.sd_content, {SD_ENUMERATION}.left)
				header_tool.sd_content.set_relative (template_tool.sd_content, {SD_ENUMERATION}.left)

				information_tool.set_focus
			end

			window.set_title ("Collection-JSON explorer")
			window.set_size (800, 600)

			initialize_actions

			information_tool.set_focus
			field_url.set_focus
		end

	initialize_actions
		do
			field_url.return_actions.extend (agent on_go)

			button_go.select_actions.extend (agent on_go)
			button_settings.select_actions.extend (agent on_settings)

			window.close_request_actions.extend (agent on_quit)
		end

feature -- Action

	show
		do
			window.show
		end

	on_quit
		do
			if attached docking_manager as dm then
				if dm.save_data ("layout.db") then
				else
					-- .. too bad
				end
			end
			window.destroy_and_exit_if_last
		end

	on_go
		local
			l_url: STRING_32
		do
			l_url := field_url.text
			explore (l_url.to_string_8)
		end

	on_settings
		local
			dlg: EV_DIALOG
			tog: EV_TOGGLE_BUTTON
			vb: EV_VERTICAL_BOX
			but: EV_BUTTON
		do
			create dlg
			create vb
			dlg.extend (vb)
			if attached docking_manager as dm then
				across
					dm.contents as c
				loop
					create tog.make_with_text ({STRING_32} "Show " + c.item.short_title)
					tog.select_actions.extend (agent (b: EV_TOGGLE_BUTTON; ct: SD_CONTENT)
							do
								ct.show
							end(tog, c.item))
					vb.extend (tog)
				end
			end
			create but.make_with_text_and_action ("Close", agent dlg.destroy_and_exit_if_last)
			dlg.set_default_cancel_button (but)
			dlg.focus_out_actions.extend (agent dlg.destroy_and_exit_if_last)
			dlg.show
		end

feature -- Access

	cj_client_proxy: CJ_CLIENT_PROXY

	last_collection: detachable CJ_COLLECTION

feature -- Explore

	set_field_url_from_location (s: READABLE_STRING_GENERAL)
		do
			field_url.set_text (s)
		end

	explore_query (q: CJ_QUERY)
		local
			retried: BOOLEAN
		do
			last_collection := Void
			if not retried then
				set_field_url_from_location (q.href)
				window.set_pointer_style (stock_pixmaps.Busy_cursor)
				if
					attached cj_client_proxy.query (q, Void) as resp
				then
					set_response (resp)
				end
			end
			window.set_pointer_style (stock_pixmaps.Standard_cursor)
		rescue
			retried := True
			retry
		end

	updated_context (a_ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): detachable HTTP_CLIENT_REQUEST_CONTEXT
		local
			ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT
		do
			ctx := a_ctx
			if attached header_tool as htool and then attached htool.header as h then
				if not h.is_empty then
					if ctx = Void then
						create ctx.make
						across
							h.to_name_value_iterable as c
						loop
							ctx.add_header (c.item.name, c.item.value)
						end
					end
				end
			end
			Result := ctx
		end

	explore (a_url: READABLE_STRING_GENERAL)
		local
			retried: BOOLEAN
		do
			last_collection := Void
			if not retried then
				set_field_url_from_location (a_url)
				window.set_pointer_style (stock_pixmaps.Busy_cursor)

				if
					attached cj_client_proxy.get (a_url, Void) as resp
				then
					set_response (resp)
				end
			end

			window.set_pointer_style (stock_pixmaps.Standard_cursor)
		rescue
			retried := True
			retry
		end

	set_response (resp: CJ_CLIENT_RESPONSE)
		local
			t: CLICKABLE_TEXT
			i: INTEGER
			retried: BOOLEAN
		do
			if not retried then
				set_field_url_from_location (resp.href)

				set_queries_tab_displayed (False)
				set_template_tab_displayed (False)

				create t.make
				t.set_foreground_color ("title", create {EV_COLOR}.make_with_8_bit_rgb (180, 0, 0))
				t.set_foreground_color ("link", create {EV_COLOR}.make_with_8_bit_rgb (0, 0, 255))
				t.set_foreground_color ("button", create {EV_COLOR}.make_with_8_bit_rgb (255, 255, 255))
				t.set_background_color ("button", create {EV_COLOR}.make_with_8_bit_rgb (0, 0, 128))

				t.set_foreground_color ("edit", create {EV_COLOR}.make_with_8_bit_rgb (255, 255, 255))
				t.set_background_color ("edit", create {EV_COLOR}.make_with_8_bit_rgb (0, 0, 90))

				t.set_foreground_color ("delete", create {EV_COLOR}.make_with_8_bit_rgb (255, 255, 255))
				t.set_background_color ("delete", create {EV_COLOR}.make_with_8_bit_rgb (128, 0, 0))



				t.append_custom ("title", "Location: " + resp.href)
				t.append_new_line

				text_http_response.set_text (resp.http_response)
				if attached resp.body as b then
					text_formatted_body.set_json (b)
				else
					text_formatted_body.wipe_out
				end
				if attached resp.collection as coll then
					last_collection := coll
					t.enter_bold
					t.append_text ("- Version: ")
					t.exit_bold
					t.append_text (coll.version)
					t.append_new_line

					t.enter_bold
					t.append_text ("- Href: ")
					t.exit_bold

					if coll.href.is_empty then
						t.append_text ("no href")
					else
						t.append_link (Void, coll.href)
					end
					t.append_new_line
					if attached coll.links as l_links then
						t.append_custom ("title", "Collection Links")
						t.append_new_line
						i := 0
						across
							l_links as c
						loop
							i := i + 1
							append_link_line_to (i, c.item, t)
							t.append_new_line
						end

						t.append_new_line
						across
							l_links as c
						loop
							i := i + 1
							append_button_link_to (c.item, t)
							t.append_text (" ")
						end
						t.append_new_line
					end

					if attached coll.items as l_items then
						t.append_custom ("title", "Items")
						t.append_new_line
						i := 0
						across
							l_items as c
						loop
							i := i + 1
--							append_item_line_to (i, c.item, t)
							append_item_to (i, c.item, t)
							t.append_new_line
						end
						t.append_new_line
					else
						t.append_custom ("title", "No Items")
						t.append_new_line
					end
					if attached coll.queries as l_queries then
						queries_tool.set_queries (coll, l_queries)
						set_queries_tab_displayed (True)
						t.append_custom ("title", "Queries")
						t.append_new_line
						i := 0
						across
							l_queries as c
						loop
							i := i + 1
							append_query_to (i, c.item, t)
							t.append_new_line
						end
						t.append_new_line
					end

					if attached coll.template as l_template then
						template_tool.set_template (coll, l_template)
						set_template_tab_displayed (True)

						t.append_custom ("title", "Template")
						t.append_new_line
						append_template_to (0, l_template, t)
						t.append_new_line
					end

					if attached coll.error as l_error then
						append_error_to (l_error, t)
						t.append_new_line
					end
				end
				information_tool.set_text_widget (t)
				information_tool.set_focus

				t.link_activated_actions.extend (agent handle_url)
			end
		rescue
			retried := True
			retry
		end

	delete (a_url: READABLE_STRING_GENERAL)
		do

		end

	edit (a_url: READABLE_STRING_GENERAL)
		do

		end

	handle_url (a_location: READABLE_STRING_8)
		local
			loc: READABLE_STRING_8
		do
			if a_location.starts_with (cj_explorer_scheme) then
				loc := a_location.substring (cj_explorer_scheme.count + 1, a_location.count)
				loc := url_encoder.decoded_string (loc)
				explore (loc)
			elseif a_location.starts_with (cj_edit_scheme) then
				loc := a_location.substring (cj_edit_scheme.count + 1, a_location.count)
				loc := url_encoder.decoded_string (loc)
				edit (loc)
			elseif a_location.starts_with (cj_delete_scheme) then
				loc := a_location.substring (cj_delete_scheme.count + 1, a_location.count)
				loc := url_encoder.decoded_string (loc)
				delete (loc)
			else
				launch_url (a_location)
			end
		end

	launch_url (a_location: READABLE_STRING_GENERAL)
		local
			e: EXECUTION_ENVIRONMENT
			cmd: STRING_32
		do
			create e
			if {PLATFORM}.is_windows then
				create cmd.make_empty
				if attached e.get ("ComSpec") as l_comspec then
					cmd.append (l_comspec)
					cmd.append_string_general (" /c ")
				end
				cmd.append_string_general ("start ")
				cmd.append_string_general (a_location)
				e.launch (cmd)
			end
		end

	append_error_to (a_error: CJ_ERROR; t: CLICKABLE_TEXT)
		do
			t.enter_bold
			t.append_text ("ERROR[")
			t.exit_bold
			t.append_text (a_error.code)
			t.enter_bold
			t.append_text ("] ")
			t.append_text (a_error.title)
			t.exit_bold
			t.append_new_line
			t.enter_italic
			t.append_text (a_error.message)
			t.exit_italic
			t.append_new_line

		end

	append_link_line_to (a_index: INTEGER; a_link: CJ_LINK; t: CLICKABLE_TEXT)
		local
			l_title: READABLE_STRING_32
		do
			if attached a_link.prompt as l_prompt then
				l_title := l_prompt
			elseif attached a_link.name as l_name then
				l_title := l_name
			else
				l_title := a_link.rel
			end

			t.enter_bold
			t.append_text (" - Link #" + a_index.out)
			t.exit_bold
			t.append_text (" ")
			t.append_link (l_title + {STRING_32} " ( "+ a_link.href + {STRING_32} " )", explorer_url (a_link.href))

			t.append_text (" ")
			append_button_href_to ("Open", raw_url (a_link.href), t)
		end

	append_button_link_to (a_link: CJ_LINK; t: CLICKABLE_TEXT)
		do
			append_button_href_to (a_link.rel, explorer_url (a_link.href), t)
		end

	append_button_href_to (a_title: READABLE_STRING_32; a_location: READABLE_STRING_8; t: CLICKABLE_TEXT)
		do
			t.append_custom_link ("button", {STRING_32} " " + a_title + {STRING_32} " ", a_location)
		end

	append_query_line_to (a_index: INTEGER; a_query: CJ_QUERY; t: CLICKABLE_TEXT)
		local
			l_title: READABLE_STRING_32
		do
			if attached a_query.prompt as l_prompt then
				l_title := l_prompt
			elseif attached a_query.name as l_name then
				l_title := l_name
			else
				l_title := a_query.rel
			end

			t.enter_bold
			t.append_text (" - Query #" + a_index.out)
			t.exit_bold
			t.append_text (" ")
			t.append_link (l_title + {STRING_32} " ( "+ a_query.href + {STRING_32} " )", a_query.href)
		end

	append_query_to (a_index: INTEGER; a_query: CJ_QUERY; t: CLICKABLE_TEXT)
		do
			append_query_line_to (a_index, a_query, t)
			t.append_new_line
			if attached a_query.data as l_data then
				t.enter_bold
				t.append_text ("%TData")
				t.exit_bold
				t.append_new_line
				across
					l_data as d
				loop
					t.append_text ("%T - ")
					append_data_line_to (d.item, t)
					t.append_new_line
				end
			end
			t.append_new_line
		end

	append_template_to (a_index: INTEGER; a_template: CJ_TEMPLATE; t: CLICKABLE_TEXT)
		do
			t.enter_bold
			t.append_text (" - Template")
			if a_index > 0 then
				t.append_text (" #" + a_index.out)
			end
			t.exit_bold
			t.append_new_line

			t.append_new_line
			if attached a_template.data as l_data then
				t.enter_bold
				t.append_text ("%TData")
				t.exit_bold
				t.append_new_line
				across
					l_data as d
				loop
					t.append_text ("%T - ")
					append_data_line_to (d.item, t)
					t.append_new_line
				end
			end
			t.append_new_line
		end

	append_item_line_to (a_index: INTEGER; a_item: CJ_ITEM; t: CLICKABLE_TEXT)
		do
			t.append_link (" - Item #" + a_index.out + " " + a_item.href, explorer_url (a_item.href))
			t.append_text (" ")
			append_button_href_to ("Open", raw_url (a_item.href), t)
		end

	append_item_to (a_index: INTEGER; a_item: CJ_ITEM; t: CLICKABLE_TEXT)
		local
			i: INTEGER
		do
			append_item_line_to (a_index, a_item, t)
			if attached a_item.data as l_data then
--				t.append_text (" ")				
--				t.append_custom_link ("edit", " Edit ", edit_url (a_item.href))
				t.append_text (" ")
				t.append_custom_link ("delete", " Delete ", delete_url (a_item.href))
				t.append_text (" ")
				t.append_text ("%N%T")
				t.enter_bold
				t.append_text ("Data")
				t.exit_bold
				across
					l_data as d
				loop
					t.append_text ("%N%T%T")
					append_data_line_to (d.item, t)
				end
			end
			if attached a_item.links as l_links then
				t.append_text ("%N%T")
				t.enter_bold
				t.append_text ("Links")
				t.exit_bold
				i := 0
				across
					l_links as ln
				loop
					t.append_text ("%N%T%T")
					i := i + 1
					append_link_line_to (i, ln.item, t)
				end
			end
			t.append_new_line
		end

	append_data_line_to (a_data: CJ_DATA; t: CLICKABLE_TEXT)
		do
			t.enter_bold
			if attached a_data.prompt as l_prompt then
				t.append_text (l_prompt)
			else
				t.append_text (a_data.name)
			end
			t.exit_bold
			if attached a_data.value as l_value then
				t.append_text ("=")
				t.enter_italic
				t.append_text (l_value)
				t.exit_italic
			end
		end

feature -- Tools

	information_tool: CJ_INFORMATION_TOOL

	queries_tool: CJ_QUERIES_TOOL

	template_tool: CJ_TEMPLATE_TOOL

	formatted_body_tool: CJ_FORMATTED_BODY_TOOL

	http_response_tool: CJ_HTTP_RESPONSE_TOOL

	header_tool: CJ_HEADER_TOOL

feature -- Widget

--	tabs: detachable EV_NOTEBOOK

	field_url: EV_TEXT_FIELD

	text_formatted_body: JSON_FORMATTED_TEXT
		do
			Result := formatted_body_tool.text
		end

	text_http_response: EV_TEXT
		do
			Result := http_response_tool.text
		end

	button_go,
	button_settings: EV_BUTTON

	stock_pixmaps: EV_STOCK_PIXMAPS
		once
			create Result
		end

feature -- UI widgets

	docking_manager: SD_DOCKING_MANAGER

	set_template_tab_displayed (b: BOOLEAN)
		do
			if b then
				template_tool.show
				template_tool.sd_content.set_long_title (template_tool.title)
			else
--				template_tool.hide
				template_tool.clear
				template_tool.sd_content.set_long_title ("No Template")
			end
		end

	set_queries_tab_displayed (b: BOOLEAN)
		do
			if b then
				queries_tool.show
				queries_tool.sd_content.set_long_title (queries_tool.title)
			else
--				queries_tool.hide
				queries_tool.clear
				queries_tool.sd_content.set_long_title ("No Queries")
			end
		end

feature -- Helper

	cj_explorer_scheme: STRING = "cj://explore/"
	cj_edit_scheme: STRING = "cj://edit/"
	cj_delete_scheme: STRING = "cj://delete/"

	explorer_url (a_location: READABLE_STRING_8): READABLE_STRING_8
		do
			Result := cj_explorer_scheme + url_encoder.encoded_string (a_location)
		end

	edit_url (a_location: READABLE_STRING_8): READABLE_STRING_8
		do
			Result := cj_edit_scheme + url_encoder.encoded_string (a_location)
		end

	delete_url (a_location: READABLE_STRING_8): READABLE_STRING_8
		do
			Result := cj_delete_scheme + url_encoder.encoded_string (a_location)
		end

	raw_url (a_location: READABLE_STRING_8): READABLE_STRING_8
		do
			Result := a_location
		end

	url_encoder: URL_ENCODER
		once
			create Result
		end

end
