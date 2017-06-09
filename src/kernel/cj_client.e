note
	description: "Summary description for {CJ_CLIENT}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

class
	CJ_CLIENT

create
	make

feature {NONE} -- Initialization

	make (a_service: READABLE_STRING_8)
			-- Initialize `Current'.
		do
			create {LIBCURL_HTTP_CLIENT_SESSION} client.make (a_service) --"http://jfiat.dyndns.org:8190")
			client.set_timeout (25)
		end

feature -- Access		

	client: HTTP_CLIENT_SESSION

	get (a_path: READABLE_STRING_GENERAL; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): CJ_CLIENT_RESPONSE
		local
			l_http_response: STRING_8
			j_body: like json
			l_formatted_body: detachable STRING_8
			col: detachable CJ_COLLECTION
			l_ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT
			l_url: STRING_8
		do
			create l_http_response.make_empty
			l_ctx := ctx
			if l_ctx = Void then
				create l_ctx.make
			end
			l_ctx.add_header ("Accept", "application/vnd.collection+json")
			l_url := a_path.to_string_8
			if attached client.get (l_url, l_ctx) as g_response then
				l_url := g_response.url
				l_http_response.append ("Status: " + g_response.status.out + "%N")
				l_http_response.append (g_response.raw_header)
				if attached g_response.body as l_body then
					l_http_response.append ("%N%N")
					l_http_response.append (l_body)
					if attached json (l_body) as j then
						j_body := j
						col := cj_collection (j)
					end
				else
					l_formatted_body := Void
				end
			end
			create Result.make (l_url, l_http_response, j_body, col)
		end

	create_with_template (a_path: READABLE_STRING_GENERAL; tpl: CJ_TEMPLATE; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): CJ_CLIENT_RESPONSE
		local
			l_http_response: STRING_8
			j_body: like json
			l_formatted_body: detachable STRING_8
			col: detachable CJ_COLLECTION
			d: detachable STRING_8
			l_ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT
			l_url: STRING_8
		do
			create l_http_response.make_empty
			l_ctx := ctx
			if l_ctx = Void then
				create l_ctx.make
			end
			l_ctx.add_header ("Accept", "application/vnd.collection+json")
			l_ctx.add_header ("Content-Type", "application/vnd.collection+json")

			if attached cj_template_to_json (tpl) as j then
				d := "{ %"template%": " + j.representation + " }"
			end

			l_url := a_path.to_string_8
			if attached client.post (l_url, l_ctx, d) as g_response then
				l_url := g_response.url
				l_http_response.append ("Status: " + g_response.status.out + "%N")
				l_http_response.append (g_response.raw_header)
				if attached g_response.body as l_body then
					l_http_response.append ("%N%N")
					l_http_response.append (l_body)
					if attached json (l_body) as j then
						j_body := j
						col := cj_collection (j)
					end
				else
					l_formatted_body := Void
				end
			end
			create Result.make (l_url, l_http_response, j_body, col)
		end

	update_with_template (a_path: READABLE_STRING_GENERAL; tpl: CJ_TEMPLATE; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): CJ_CLIENT_RESPONSE
		local
			l_http_response: STRING_8
			j_body: like json
			l_formatted_body: detachable STRING_8
			col: detachable CJ_COLLECTION
			d: detachable STRING_8
			l_ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT
			l_url: STRING_8
		do
			create l_http_response.make_empty
			l_ctx := ctx
			if l_ctx = Void then
				create l_ctx.make
			end
			l_ctx.add_header ("Content-Type", "application/vnd.collection+json")
			l_ctx.add_header ("Accept", "application/vnd.collection+json")


			if attached cj_template_to_json (tpl) as j then
				d := "{ %"template%": " + j.representation + " }"
			end

			l_url := a_path.to_string_8
			if attached client.put (l_url, l_ctx, d) as g_response then
				l_url := g_response.url
				l_http_response.append ("Status: " + g_response.status.out + "%N")
				l_http_response.append (g_response.raw_header)
				if attached g_response.body as l_body then
					l_http_response.append ("%N%N")
					l_http_response.append (l_body)
					if attached json (l_body) as j then
						j_body := j
						col := cj_collection (j)
					end
				else
					l_formatted_body := Void
				end
			end
			create Result.make (l_url, l_http_response, j_body, col)
		end

	query (q: CJ_QUERY; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): CJ_CLIENT_RESPONSE
		local
			l_http_response: STRING_8
			j_body: like json
			l_formatted_body: detachable STRING_8
			col: detachable CJ_COLLECTION
			l_ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT
			l_url: STRING_8
		do
			create l_http_response.make_empty
			l_ctx := ctx
			if l_ctx = Void then
				create l_ctx.make
			end
			l_ctx.add_header ("Content-Type", "application/vnd.collection+json")
			l_ctx.add_header ("Accept", "application/vnd.collection+json")


			if attached q.data as q_data then
				across
					q_data as d
				loop
					if attached d.item.value as l_val then
						l_ctx.add_query_parameter (d.item.name, l_val)
					end
				end
			end

--			if attached cj_query_to_json (tpl) as j then
--				d := "{ %"template%": " + j.representation + " }"
--			end
			l_url := q.href
			if attached client.get (q.href, l_ctx) as g_response then
				l_url := g_response.url
				l_http_response.append ("Status: " + g_response.status.out + "%N")
				l_http_response.append (g_response.raw_header)
				if attached g_response.body as l_body then
					l_http_response.append ("%N%N")
					l_http_response.append (l_body)
					if attached json (l_body) as j then
						j_body := j
						col := cj_collection (j)
					end
				else
					l_formatted_body := Void
				end
			end
			create Result.make (l_url, l_http_response, j_body, col)
		end


	delete (a_path: READABLE_STRING_GENERAL; ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT): CJ_CLIENT_RESPONSE
		local
			l_http_response: STRING_8
			j_body: like json
			l_formatted_body: detachable STRING_8
			col: detachable CJ_COLLECTION
			l_ctx: detachable HTTP_CLIENT_REQUEST_CONTEXT
			l_url: STRING_8
		do
			create l_http_response.make_empty
			l_ctx := ctx
			if l_ctx = Void then
				create l_ctx.make
			end
			l_ctx.add_header ("Accept", "application/vnd.collection+json")
			l_url := a_path.to_string_8
			if attached client.delete (l_url, l_ctx) as g_response then
				l_url := g_response.url
				l_http_response.append ("Status: " + g_response.status.out + "%N")
				l_http_response.append (g_response.raw_header)
				if attached g_response.body as l_body then
					l_http_response.append ("%N%N")
					l_http_response.append (l_body)
					if attached json (l_body) as j then
						j_body := j
						col := cj_collection (j)
					end
				else
					l_formatted_body := Void
				end
			end
			create Result.make (l_url, l_http_response, j_body, col)
		end


feature {NONE} -- Implementation

	shared_ejson: SHARED_EJSON
		once
			create Result
		end

	initialize_json_converters
		once
			if attached shared_ejson.json as j then
				j.add_converter (create {CJ_COLLECTION_JSON_CONVERTER}.make)
				j.add_converter (create {CJ_DATA_JSON_CONVERTER}.make)
				j.add_converter (create {CJ_ERROR_JSON_CONVERTER}.make)
				j.add_converter (create {CJ_ITEM_JSON_CONVERTER}.make)
				j.add_converter (create {CJ_QUERY_JSON_CONVERTER}.make)
				j.add_converter (create {CJ_TEMPLATE_JSON_CONVERTER}.make)
				j.add_converter (create {CJ_LINK_JSON_CONVERTER}.make)
				if j.converter_for (create {ARRAYED_LIST [detachable ANY]}.make (0)) = Void then
					j.add_converter (create {CJ_ARRAYED_LIST_JSON_CONVERTER}.make)
				end
			end
		end

feature -- Access		

	cj_collection (j: JSON_VALUE): detachable CJ_COLLECTION
		local
			conv: CJ_COLLECTION_JSON_CONVERTER
		do
			if attached {JSON_OBJECT} j as jo then
				initialize_json_converters
				create conv.make
				Result := conv.from_json (jo)
			end
		end

	json (s: READABLE_STRING_8): detachable JSON_VALUE
		local
			p: JSON_PARSER
		do
			create p.make_with_string (s)
			p.parse_content
			if
				attached p.parsed_json_value as v and then
				p.is_parsed
			then
				Result := v
			end
		end

	cj_template_to_json (tpl: CJ_TEMPLATE): detachable JSON_VALUE
		local
			conv: CJ_TEMPLATE_JSON_CONVERTER
		do
			initialize_json_converters
			create conv.make
			Result := conv.to_json (tpl)
		end

end
