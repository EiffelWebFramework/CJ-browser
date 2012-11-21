note
	description: "Summary description for {CJ_TOOL}."
	author: ""
	date: "$Date$"
	revision: "$Revision$"

deferred class
	CJ_TOOL

feature {NONE} -- Initialization

	make (cl: like cj_client)
		do
			cj_client := cl
			create_interface_objects
			initialize
		end

	create_interface_objects
		deferred
		end

	initialize
		do
			create sd_content.make_with_widget (widget, title)
			sd_content.set_short_title (title)
			sd_content.set_long_title (title)
			sd_content.close_request_actions.extend (agent hide)
		end

feature -- Access

	cj_client: CJ_CLIENT

	title: STRING_32
		deferred
		end

	sd_content: SD_CONTENT

	widget: EV_WIDGET
		deferred
		end

feature -- Event

	show
		do
			sd_content.show
		end

	hide
		do
			sd_content.hide
		end

	set_focus
		do
			sd_content.set_focus
		end


end
