note
	description: "Objects that ..."
	author: "$Author$"
	date: "$Date$"
	revision: "$Revision$"

class
	CJ_CLIENT_APPLICATION

inherit
	EV_APPLICATION

create
	make_and_launch

feature {NONE} -- Initialization

	make_and_launch
		local
			w: CJ_CLIENT_WINDOW
			args: ARGUMENTS
		do
			default_create

			create w
			main_window := w
			w.show

			create args
			if args.argument_count > 0 then
				w.set_field_url_from_location (args.argument (1))
			end

			launch
		end

feature {NONE} -- Implementation

	main_window: detachable CJ_CLIENT_WINDOW

end
