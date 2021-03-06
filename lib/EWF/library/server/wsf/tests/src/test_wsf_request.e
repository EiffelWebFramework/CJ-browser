note
	description: "[
		Eiffel tests that can be executed by testing tool.
	]"
	author: "EiffelStudio test wizard"
	date: "$Date$"
	revision: "$Revision$"
	testing: "type/manual"

class
	TEST_WSF_REQUEST

inherit
	EQA_TEST_SET
		redefine
			on_prepare,
			on_clean
		end

	WSF_SERVICE
		undefine
			default_create
		end

feature {NONE} -- Events

	web_app: detachable NINO_SERVICE

	port_number: INTEGER
	base_url: detachable STRING

	on_prepare
			-- <Precursor>
		local
			app: NINO_SERVICE
			wt: WORKER_THREAD
			e: EXECUTION_ENVIRONMENT
		do
--			port_number := 9091
			port_number := 0
			base_url := "test/"
			create app.make_custom (to_wgi_service, base_url)
			web_app := app

			create wt.make (agent app.listen (port_number))
			wt.launch

			create e
			e.sleep (1_000_000_000 * 5)

			port_number := app.port
		end

	server_log_name: STRING
		local
			fn: FILE_NAME
		once
			create fn.make_from_string ("..")
			fn.extend ("..")
			fn.extend ("..")
			fn.extend ("..")
			fn.extend ("..")
			fn.extend ("server_test.log")
			Result := fn.string
		end

	server_log (m: STRING_8)
		local
			f: RAW_FILE
		do
			create f.make_open_append (server_log_name)--"..\server-tests.log")
			f.put_string (m)
			f.put_character ('%N')
			f.close
		end

	execute (req: WSF_REQUEST; res: WSF_RESPONSE)
		local
			q: detachable STRING_32
			n: NATURAL_64
			page: WSF_PAGE_RESPONSE
		do
			debug
				server_log (req.request_uri)
				if attached req.content_type as l_content_type then
					server_log ("content_type:" + l_content_type.string)
				end
			end

			create page.make
			if attached req.request_uri as l_uri then
				if l_uri.starts_with (test_url ("get/01")) then
					page.set_status_code (200)
					page.header.put_content_type_text_plain
					page.put_string ("get-01")
					create q.make_empty

					across
						req.query_parameters as qcur
					loop
						if not q.is_empty then
							q.append_character ('&')
						end
						q.append (qcur.item.name.as_string_32 + "=" + qcur.item.as_string)
					end
					if not q.is_empty then
						page.put_string ("(" + q + ")")
					end
				elseif l_uri.starts_with (test_url ("post/01")) then
					page.put_header (200, <<["Content-Type", "text/plain"]>>)
					page.put_string ("post-01")
					create q.make_empty

					across
						req.query_parameters as qcur
					loop
						if not q.is_empty then
							q.append_character ('&')
						end
						q.append (qcur.item.name.as_string_32 + "=" + qcur.item.as_string)
					end

					if not q.is_empty then
						page.put_string ("(" + q + ")")
					end

					create q.make_empty
--					req.set_raw_input_data_recorded (True)

					across
						req.form_parameters as fcur
					loop
						debug
							server_log ("%Tform: " + fcur.item.name)
						end
						if not q.is_empty then
							q.append_character ('&')
						end
						q.append (fcur.item.name.as_string_32 + "=" + fcur.item.as_string)
					end

--					if attached req.raw_input_data as d then
--						server_log ("Raw data=" + d)
--					end

					if not q.is_empty then
						page.put_string (" : " + q )
					end
				elseif l_uri.starts_with (test_url ("post/file/01")) then
					page.put_header (200, <<["Content-Type", "text/plain"]>>)
					page.put_string ("post-file-01")
					n := req.content_length_value
					if n > 0 then
						req.input.read_string (n.to_integer_32)
						q := req.input.last_string
						page.put_string ("%N" + q)
					end
				else
					page.put_header (200, <<["Content-Type", "text/plain"]>>)
					page.put_string ("Hello")
				end
			else
				page.put_header (200, <<["Content-Type", "text/plain"]>>)
				page.put_string ("Bye")
			end

			res.send (page)
		end

	test_url (a_query_url: READABLE_STRING_8): READABLE_STRING_8
		local
			b: like base_url
		do
			b := base_url
			if b = Void then
				b := ""
			end
			Result := "/" + b + a_query_url
		end

	on_clean
			-- <Precursor>
		do
			if attached web_app as app then
				app.shutdown
			end
		end

	http_session: detachable HTTP_CLIENT_SESSION

	get_http_session
		local
			h: LIBCURL_HTTP_CLIENT
			b: like base_url
		do
			create h.make
			b := base_url
			if b = Void then
				b := ""
			end
			if attached {HTTP_CLIENT_SESSION} h.new_session ("localhost:" + port_number.out + "/" + b) as sess then
				http_session := sess
				sess.set_timeout (-1)
				sess.set_is_debug (True)
				sess.set_connect_timeout (-1)
--				sess.set_proxy ("127.0.0.1", 8888) --| inspect traffic with http://www.fiddler2.com/								
			end
		end

	test_get_request (a_url: READABLE_STRING_8; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT; a_expected_body: READABLE_STRING_8)
		do
			get_http_session
			if attached http_session as sess then
				if attached sess.get (a_url, adapted_context (ctx)) as res and then not res.error_occurred and then attached res.body as l_body then
					assert ("Good answer got=%""+l_body+"%" expected=%""+a_expected_body+"%"", l_body.same_string (a_expected_body))
				else
					assert ("Request %""+a_url+"%" failed", False)
				end
			end
		end

	test_post_request (a_url: READABLE_STRING_8; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT; a_expected_body: READABLE_STRING_8)
		do
			get_http_session
			if attached http_session as sess then
				if attached sess.post (a_url, adapted_context (ctx), Void) as res and then not res.error_occurred and then attached res.body as l_body then
					assert ("Good answer got=%""+l_body+"%" expected=%""+a_expected_body+"%"", l_body.same_string (a_expected_body))
				else
					assert ("Request %""+a_url+"%" failed", False)
				end
			end
		end

	test_post_request_with_filename (a_url: READABLE_STRING_8; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT; a_fn: STRING; a_expected_body: READABLE_STRING_8)
		do
			get_http_session
			if attached http_session as sess then
				if attached sess.post_file (a_url, adapted_context (ctx), a_fn) as res and then not res.error_occurred and then attached res.body as l_body then
					assert ("Good answer got=%""+l_body+"%" expected=%""+a_expected_body+"%"", l_body.same_string (a_expected_body))
				else
					assert ("Request %""+a_url+"%" failed", False)
				end
			end
		end

	adapted_context (ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): HTTP_CLIENT_REQUEST_CONTEXT
		do
			if ctx /= Void then
				Result := ctx
			else
				create Result.make
			end
--			Result.set_proxy ("127.0.0.1", 8888) --| inspect traffic with http://www.fiddler2.com/			
		end

feature -- Test routines

	test_get_request_01
			-- New test routine
		do
			get_http_session
			if attached http_session as sess then
				test_get_request ("get/01", Void, "get-01")
				test_get_request ("get/01/?foo=bar", Void, "get-01(foo=bar)")
				test_get_request ("get/01/?foo=bar&abc=def", Void, "get-01(foo=bar&abc=def)")
				test_get_request ("get/01/?lst=a&lst=b", Void, "get-01(lst=[a,b])")
			else
				assert ("not_implemented", False)
			end
		end

	test_post_request_uploaded_file
			-- New test routine
		local
			fn: FILE_NAME
			f: RAW_FILE
			s: STRING
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
		do
			get_http_session
			if attached http_session as sess then
				create fn.make_temporary_name
				create f.make_create_read_write (fn.string)
				s := "This is an uploaded file%NTesting purpose%N"
				f.put_string (s)
				f.close
				test_post_request_with_filename ("post/file/01", Void, fn.string, "post-file-01%N" + s)

				create ctx.make
				ctx.add_form_parameter ("foo", "bar")
				test_post_request_with_filename ("post/file/01", ctx, fn.string, "post-file-01%N" + s)
			else
				assert ("not_implemented", False)
			end
		end

	test_post_request_01
			-- New test routine
		local
			ctx: HTTP_CLIENT_REQUEST_CONTEXT
		do
			get_http_session
			if attached http_session as sess then
				create ctx.make
				ctx.add_form_parameter ("id", "123")
				ctx.add_form_parameter ("Eiffel", "Web")
				test_post_request ("post/01", ctx, "post-01 : " + ctx.form_parameters_to_url_encoded_string)
				test_post_request ("post/01/?foo=bar", ctx, "post-01(foo=bar) : " + ctx.form_parameters_to_url_encoded_string)
				test_post_request ("post/01/?foo=bar&abc=def", ctx, "post-01(foo=bar&abc=def) : " + ctx.form_parameters_to_url_encoded_string)
				test_post_request ("post/01/?lst=a&lst=b", ctx, "post-01(lst=[a,b]) : " + ctx.form_parameters_to_url_encoded_string)
			else
				assert ("not_implemented", False)
			end
		end

end


