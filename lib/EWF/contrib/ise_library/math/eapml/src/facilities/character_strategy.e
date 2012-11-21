note
	description: "A strategy for converting character codes to numbers and vica-versa"
	author: "Colin LeMahieu"
	date: "$Date: 2011-11-11 18:13:16 +0100 (ven., 11 nov. 2011) $"
	revision: "$Revision: 87787 $"
	quote: "Free speech is meaningless unless it tolerates the speech that we hate. -  Henry J. Hyde, U.S. Congressman, Speech, 5/3/91"

deferred class
	CHARACTER_STRATEGY

feature

	text_to_number (in: NATURAL_8): NATURAL_8
		deferred
		end

	number_to_text (in: NATURAL_8): NATURAL_8
		deferred
		end
end
