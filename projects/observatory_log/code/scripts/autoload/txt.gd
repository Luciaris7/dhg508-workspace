extends Node
## All player-facing copy, English and Simplified Chinese.
##
## Tone (user, 2026-11-12): cold and alone. Inner monologue is kept to the
## lines the setting document requires plus the shortest possible hints that
## stop a player getting stuck. Hints name the object, never explain.
## Lines marked SET are the setting document's own wording (zh is verbatim).
## Unknown ids return "" -- never invent copy at a call site.

const ZH := preload("res://scripts/autoload/txt_zh.gd")

const PHONE := [
	"Hey. New guy. I'm the one who had this job before you. Not anymore.",
	"Your whole job is staring at that damn screen, looking at a picture that won't change for another hundred years.",
	"Oh, and the locals will tell you about the lights. Red, over Birch Lake, once every thirteen years. Some swear there's a building out in the middle of the ice. Small-town stuff.",
	"Work instructions are on the desktop. Read them. I didn't.",
	"Weather report: snow, then more snow. That's the whole forecast. You're welcome.",
]

const NOTICE := [
	"SITE 7 OBSERVATORY - WORK NOTICE",
	"Doc. No. SITE7-SOP-04      General Edition",
	"",
	"This notice sets out the observer's daily work.",
	"Carry out the work in the order given.",
	"",
	"1. DAILY WORK",
	"1.1 Power.",
	"1.2 Lake survey.",
	"1.3 Night observation and report.",
	"",
	"2. PROCEDURE 1 - POWER",
	"2.1 The generator is in the shed east of the tower.",
	"2.2 Fill the generator tank from the diesel can.",
	"2.3 Pull the starter cord until the engine runs. The indicator lamp is red when running.",
	"",
	"3. PROCEDURE 2 - LAKE SURVEY",
	"3.1 The echo sounder is kept on the shed workbench.",
	"3.2 Survey points: A, the boathouse jetty on the north shore; B, the water hole at the site jetty.",
	"3.3 At each point, set the bearing and send a pulse until an echo is logged.",
	"3.4 Results are saved automatically.",
	"",
	"4. NIGHT WORK",
	"4.1 After dark, in this order:",
	"4.1.1 Aim the antenna.",
	"4.1.2 Record the star chart.",
	"4.1.3 Submit the report.",
	"4.1.4 Work is finished. Rest.",
	"",
	"4.2 Antenna",
	"4.2.1 The antenna is on the hilltop north of the site. Take the trail east of the shed.",
	"4.2.2 The correct bearing changes daily. Do not reuse the previous day's value.",
	"",
	"4.3 Star chart",
	"4.3.1 Open the star chart program on the cabin computer.",
	"4.3.2 Check the positions of the bodies. Record the image.",
	"",
	"4.4 Report",
	"4.4.1 Open the report program on the cabin computer.",
	"4.4.2 Answer the question for that day's chart and submit. One report per day.",
	"",
	"5. SCHEDULE",
	"5.1 No schedule applies on the day of arrival.",
	"5.2 From the second day, carry out the daily work in full.",
	"",
	"6. GENERAL",
	"6.1 The observer is responsible for station equipment.",
	"6.2 General edition. Local amendments do not apply.",
	"",
	"Page 1 of 1",
]

const MONO := {
	# the setting's own lines
	"d1_check_computer": "I should check the computer. It should tell me what I'm supposed to do.",   # SET
	"d2_game_hint": "That thing on the desktop looks like a game. I don't know who put it there, though.",   # SET
	"d2_forced_rest": "It's getting late. I need some rest.",   # SET
	"d3_antenna": "Maybe the antenna's just getting old. I should go back to sleep.",   # SET
	"d4_pill": "Maybe it's just living alone. I should take a sleeping pill and get some rest.",   # SET
	"d5_uranus": "Something unknown is drifting out at Uranus' orbit. I need to know if it's because that old antenna's about to give out.",   # SET
	"d5_quit": "Tomorrow I'll call maintenance and get that damn antenna replaced. One strange thing after another. I think I should quit. But right now, what I need most is a good night's sleep.",   # SET
	# hints: only what keeps a player from getting stuck
	"d2_ice": "Frozen. There's an axe in the shed.",
	"d3_cable": "No signal. A cable's loose.",
	"d3_chart": "A mark in the corner.",
	"d5_outage": "No power. The generator.",
	"d2_close_blocked": "It won't close.",
	"d7_bed": "It won't.",
	"bed_unfinished": "There's still work left. Sleep now?",
	"step_computer": "The computer.",
	"step_fuel": "The generator first.",
	"step_survey": "The survey. The lake.",
	"survey_need": "The sounder. It's on the workbench in the shed.",
	"footprints": "Bare footprints. Coming up from the lake. None going back.",
	"footprints_d4": "The footprints are closer to the station. They leave dark red marks in the snow.",
	"d5_what": "What was that.",
	"d7_wake": "It's already dark.",
	"d7_work": "The antenna.",
	"radio_static": "Static.",
	"truck_dead": "It won't start.",
	"boat_frozen": "Frozen.",
	"plug_found": "A spark plug.",
	"truck_go": "It starts.",
	"escape_shore": "Not that way.",
	"no_signal": "No signal.",
	"step_antenna": "The antenna.",
	"step_starchart": "The star chart.",
	"step_report": "The report.",
	"step_sleep": "Sleep.",
	"step_pill": "The pills. On the desk.",
	"step_inspect": "The antenna.",
	"generic_unfinished": "I still have things left to do.",
	"generic_not_yet": "Still light.",
	"generic_no_fuel": "The diesel can.",
	# only when the player looks
	"d3_plant": "Drooping.",
	"d4_plant": "Dead.",
	"d4_wall": "Dark red liquid is seeping out of the wall.",
	"d3_sky": "Something above the trees.",
}

const UI := {
	"hud.day": "Day %d",
	"card.day": "Day %d",
	"icon.notice": "notice.txt",
	"icon.chart": "STARCHART",
	"icon.report": "REPORT",
	"icon.game": "HOMEWARD",
	"icon.mycomputer": "My Computer",
	"icon.bin": "Recycle Bin",
	"icon.mydocs": "My Documents",
	"icon.log": "reports.log",
	"start": "start",
	"start.user": "Observer",
	"start.off": "Turn Off Computer",
	"menu.file": "File", "menu.edit": "Edit", "menu.format": "Format", "menu.view": "View",
	"menu.help": "Help", "menu.fav": "Favorites", "menu.tools": "Tools",
	"notice.title": "notice.txt - Notepad",
	"chart.title": "SITE 7 STARCHART",
	"chart.record": "RECORD",
	"chart.mark": "MARK",
	"chart.clear": "CLEAR",
	"chart.today": "TODAY",
	"chart.recorded": "Image recorded.",
	"chart.recording": "Recording...",
	"chart.no_signal": "NO SIGNAL - aim the antenna.",
	"chart.already": "Today's image is recorded.",
	"chart.scale": "Geocentric. Distance not to scale.",
	"chart.marks": "Marks: %d",
	"report.title": "SITE 7 REPORT - Microsoft Internet Explorer",
	"report.address": "http://site7.local/report",
	"report.addr": "Address",
	"report.go": "Go",
	"report.done_status": "Done",
	"report.zone": "Local intranet",
	"report.header": "Daily observation report",
	"report.question": "Is there any anomaly in the image? Please answer Yes/No.",
	"report.submit": "SUBMIT",
	"report.need_chart": "Record today's star chart first.",
	"report.bad": "Enter Yes or No.",
	"report.done": "Today's report has been submitted.",
	"report.received": "Report received. Thank you.",
	"report.yes2": "Observation confirmed.",
	"report.yes3": "Thank you for observing.",
	"report.yes4": "Keep observing.",
	"report.no2": "Please look again.",
	"report.no3": "Your previous answers have been corrected.",
	"report.forced": "Answer accepted.",
	"log.title": "reports.log - Notepad",
	"log.header": "DATE          ANSWER",
	"log.yes": "Yes",
	"log.no": "No",
	"log.corrected": "(corrected)",
	"log.confirmations": "REPORTS RECEIVED: %d / 7",
	"mycomputer.title": "My Computer",
	"mycomputer.c": "Local Disk (C:)",
	"mycomputer.a": "3 1/2 Floppy (A:)",
	"bin.title": "Recycle Bin",
	"bin.empty": "The Recycle Bin is empty.",
	"mydocs.title": "My Documents",
	"mydocs.empty": "This folder is empty.",
	"folder.tasks": "Tasks",
	"folder.details": "View details",
	"record.title": "chart_%s.bmp - Image Viewer",
	"err.access": "Access is denied.",
	"err.title": "Error",
	"err.floppy": "There is no disk in the drive.",
	"ok": "OK",
	"boot.1": "SITE 7 WORKSTATION BIOS v1.02",
	"boot.2": "Memory Test: 65536K OK",
	"boot.3": "Detecting IDE drives... ST34321A",
	"boot.4": "Starting Windows...",
	"boot.name": "Site 7 Workstation",
	"boot.os": "Windows",
	"boot.copy": "Copyright (C) Site 7",
	"antenna.title": "ANTENNA AIMING",
	"antenna.hint": "A / D  rotate      E  confirm",
	"antenna.angle": "AZIMUTH %03d",
	"antenna.locked": "SIGNAL LOCKED",
	"antenna.signal": "SIGNAL",
	"antenna.north": "N",
	"wire.title": "JUNCTION BOX",
	"wire.hint": "W / S  wire     A / D  socket     E  connect",
	"hold_e": "Hold E",
	"mash_e": "Press E",
	"task.diesel": "Diesel",
	"task.cord": "Starter cord",
	"task.crank": "Crank",
	"task.ice": "Ice",
	"task.water": "Water",
	"voicemail": "VOICEMAIL  -  1 NEW MESSAGE",
	"tip.walk": "A / D  walk      E  interact",
	"tip.desk": "Esc  leave the computer",
	"menu.new": "New Game",
	"menu.continue": "Continue  (Day %d)",
	"menu.retry": "Start again from Day %d",
	"menu.settings": "Settings",
	"menu.quit": "Quit",
	"menu.resume": "Resume",
	"menu.restart_day": "Restart Day",
	"menu.to_title": "Quit to Title",
	"menu.back": "Back",
	"menu.confirm_new": "Start over? Saved progress will be lost.",
	"menu.yes": "Yes",
	"menu.no": "No",
	"set.lang": "Language",
	"set.master": "Master volume",
	"set.music": "Music",
	"set.sfx": "Sound effects",
	"set.amb": "Ambience",
	"set.flash": "Bright flashes",
	"set.tear": "Distortion effects",
	"set.fullscreen": "Fullscreen",
	"set.on": "On",
	"set.off": "Off",
	"set.reduced": "Reduced",
	"warn.1": "This game contains flashing lights, distortion and",
	"warn.2": "images of blood and flesh. Both can be reduced in Settings.",
	"warn.3": "Headphones recommended.",
	"game.score": "SCORE %d",
	"game.best": "BEST %d",
	"game.over": "GAME OVER",
	"game.hint": "W / S  steer",
	"game.click": "click to continue",
	"controls": "A / D  walk      E  interact      Esc  menu",
	# --- the mystery
	"icon.notes": "Notes",
	"icon.archive": "ARCHIVE",
	"notes.title": "Investigation Notes - Notepad",
	"notes.count": "Records saved: %d",
	"notes.empty": "Nothing saved yet.",
	"notes.day": "Day %d",
	"notes.links": "CROSS-CHECKS",
	"notes.link1": "[LINK] The building in the notice and the survey echoes point to the same place.",
	"notes.link2": "[LINK] The red body's pulse and the rising structure keep the same rhythm.",
	"notes.link3": "[LINK] The next cycle repeats these reports. Submitted records are rewritten.",
	"notes.link4": "[LINK] The previous observer's two notes point to the same result. After the seventh report, the observer goes to the lake.",
	"notes.link5": "[LINK] The site has no weather instruments. The antenna was never recording weather.",
	"notes.radio": "Radio, night 5: numbers in Morse code, repeated. Groups of four, two, two and four digits.",
	"notes.radio_sig": "Taken down: %s",
	"notes.sealed": "Archive record %s: opened.",
	"tip.clue": "Saved to Investigation Notes",
	"tip.survey": "Survey saved to My Documents",
	"archive.title": "SITE 7 ARCHIVE",
	"archive.format": "Record no. format:  CC-SS-DD-HHMM",
	"archive.legend": "CC cycle   SS site   DD day   HHMM time",
	"archive.field": "Record no.",
	"archive.open": "OPEN",
	"archive.none": "No such record.",
	"archive.purged": "[PURGED]",
	"archive.sealed": "[SEALED]",
	"archive.report": "report",
	"archive.confirm": "confirmation",
	"archive.rec_title": "Record %s - Archive",
	"archive.report_body": "Daily report. Cycle %s, site 07, day %d, %s. Answer: %s.",
	"survey.title": "survey_%s.map - Viewer",
	"survey.lake": "BIRCH LAKE  survey grid, metres",
	"survey.chart": "Charted max depth: 12 m",
	"survey.source": "Structure top: %.1f m",
	"survey.row": "%s  %03d deg  %d m",
	"survey.struct": "Regular returns every 4 m below the structure top.",
	"survey.section": "Section, lake centre",
	"survey.pulse": "Source pulse 0.75/s.",
	"survey.shore": "shore",
	"obslog.title": "obslog_%s.txt - Notepad",
	"obslog.head": "SITE 7 - OBSERVATION LOG   CYCLE 05",
	"obslog.day": "%s  day %d  %s  report: %s",
	"obslog.last": "%s  day 7  --:--  naked-eye observation at the lake",
	"obslog.observer": "Observer: ______________",
	"sonar.title": "ECHO SOUNDER",
	"sonar.hint": "A / D  bearing    E  ping    Esc  cancel",
	"sonar.bearing": "BEARING %03d",
	"sonar.range": "RANGE   %s",
	"sonar.depth": "DEPTH   %s",
	"sonar.logged": "ECHO LOGGED",
	"sonar.point": "POINT %s",
	"radio.title": "RECEIVER   4625 kHz",
	"radio.hint": "E / Esc  close",
	"radio.card": "DIGITS",
	"doc.hint": "E  close      W / S  scroll",
	"vista.exit": "Click to exit",
	"bed.ask": "E  sleep      Esc  cancel",
	"ignition.title": "IGNITION",
	"set.assist": "Puzzle assist",
	"set.assist0": "Off",
	"set.assist1": "Signals",
	"set.assist2": "Digits",
}

const CLUE_NOTE := {
	"rumor": "Notice board: a blood-red aurora over Birch Lake once every 13 years ({y3}, {y2}, {y1}). A building seen in the middle of the lake.",
	"not_weather": "Equipment register: no weather instruments at all. The antenna is fixed on the zenith above the lake. One observer every 13 years, seven nights.",
	"footprints": "Bare footprints in the snow, from the lake toward the station. None lead back.",
	"echo_hollow": "Survey: every echo comes from one point in the middle of the lake. Something stands on the lakebed there. The returns are regular, like walls.",
	"red_body": "Star chart: a dark red body that is in no ephemeris. Closer every night.",
	"future_log": "My Documents: a log dated thirteen years from now. Cycle 05. Same procedure, same answers. The observer's name is blank.",
	"prev_notes": "The previous observer's pages: Site 7 was never meant to watch the sky. On the night of the descent there is an altar in the middle of the lake. He left what he found in the computer.",
	"echo_aurora": "Survey, night 5: the structure on the lakebed is rising, faster every day. It pulses with the red body in the chart.",
	"autocorrect": "reports.log: every Yes has been rewritten as No. The last line counts the seven reports.",
	"last_record": "A note from cycle 03: the report was changed after submission. After the seventh report, the observer goes to the lake. The spark plug was taken from the truck.",
}

const DOCS := {
	"rumor": [
		"BIRCH LAKE",
		"No fishing on the ice.",
		"",
		"Local lore - Birch Lake Historical Society",
		"Once every thirteen years a blood-red aurora is said to hang over the lake for about a week.",
		"Reported: {y3}, {y2}, {y1}.",
		"Some witnesses describe a building standing in the middle of the lake.",
		"There is no building on the lake.",
	],
	"not_weather": [
		"SITE 7 - EQUIPMENT REGISTER",
		"Commissioned {y3}.",
		"",
		"Meteorological instruments ....... none",
		"Antenna (dish, 1) ................ fixed program",
		"   target ........................ zenith above the lake",
		"Echo sounder (portable, 1) ....... lake survey",
		"Radio receiver (1) ............... do not tune",
		"",
		"Staffing: one observer per cycle.",
		"Cycle: 13 years. Duty: 7 nights.",
		"Cycles completed: 01, 02, 03.",
	],
	"prev_notes": [
		"(torn pages - the previous observer's handwriting)",
		"",
		"Site 7 was never built to watch the night sky. It is @#*&?$%!@#*&?$%!@#*&?$%!@#*&?$. On the night of the descent, at the altar in the middle of the lake, it will @#*&?$%!@#*&?$%!@#*&?$. I left everything I found these days in that computer. If anyone reads this, good luck.",
	],
	"last_record": [
		"(folded in the pocket of a coat that is not yours)",
		"",
		"CYCLE 03 - DAY 7",
		"Three days I reported an anomaly. Each morning the log said none.",
		"The report was changed after submission.",
		"After seven reports, the procedure moves to the lake.",
		"Do not go alone.",
		"The truck won't go. The spark plug is gone.",
	],
	"sealed": [
		"RECORD {sid}    REPORT    SEALED",
		"",
		"I should have seen it. Joseph spent thirteen years in these woods. After he came out here to work I never saw him again. Then he wrote and told me to take over his job - easy work, good pay. It was the first letter I'd had from him in thirteen years. It's a trap. Someone has been at my truck. I left spare parts in the boathouse, but I don't think I'll get the chance to go for them.",
	],
}

const DOC_TITLE := {
	"rumor": "Notice board",
	"not_weather": "Binder",
	"prev_notes": "Locker",
	"last_record": "Coat pocket",
}

## Credits: shown after every ending. One page per entry: [heading, lines...].
const CREDITS := [
	["", "A GAME BY LUCIA"],
	["AI MEMBERS", "GLM 5.3 Flash", "DeepSeek V4.1 Flash", "Claude Opus 5.5", "ChatGPT 6.1 Sol"],
	["THIRD PARTY", "Fusion Pixel Font 12px - TakWolf - SIL OFL 1.1", "Astronomy Engine - Don Cross - MIT", "", "Ending illustrations made with an image model.", "All other art, sound and music generated by script."],
	["", "Thank you for your observation."],
]

const RED := {
	"d7_desktop": "Thank you for your observation. Please go to the lake and observe with the naked eye.",
	"d7_move": "THE LAKESHORE OBSERVATION WILL BEGIN. DO NOT LOOK BACK.",
	"forced": "Type No",
	"reject": "THE AUDIENCE IS NOT YET GRANTED.",
	"title": "OBSERVATION LOG",
	"title_sub": "",
	"end_cycle": "CYCLE 04 COMPLETE. NEXT OBSERVATION: {yn}.",
	"later": "THIRTEEN YEARS LATER",
}

const BODIES := {
	"Sun": "Sun", "Moon": "Moon", "Earth": "Earth", "Mercury": "Mercury", "Venus": "Venus", "Mars": "Mars",
	"Jupiter": "Jupiter", "Saturn": "Saturn", "Uranus": "Uranus", "Neptune": "Neptune",
	"Io": "Io", "Europa": "Europa", "Ganymede": "Ganymede", "Callisto": "Callisto", "Titan": "Titan",
}


func zh() -> bool:
	return String(G.settings.get("lang", "en")) == "zh"


func phone() -> Array:
	return ZH.PHONE if zh() else PHONE


func notice() -> Array:
	return ZH.NOTICE if zh() else NOTICE


func mono(id: String) -> String:
	if zh():
		return String(ZH.MONO.get(id, ""))
	return String(MONO.get(id, ""))


func ui(id: String) -> String:
	if zh() and ZH.UI.has(id):
		return String(ZH.UI[id])
	return String(UI.get(id, ""))


func red(id: String) -> String:
	if zh() and ZH.RED.has(id):
		return story(String(ZH.RED[id]))
	return story(String(RED.get(id, "")))


## Fills the cycle-year tokens: {y1} {y2} {y3} = 13 / 26 / 39 years back, {yn} = 13 ahead.
func story(s: String) -> String:
	if not s.contains("{"):
		return s
	return s.replace("{y1}", str(G.cycle_year(1))).replace("{y2}", str(G.cycle_year(2))) \
		.replace("{y3}", str(G.cycle_year(3))).replace("{yn}", str(G.cycle_year(-1))) \
		.replace("{sid}", G.sealed_id())


func clue_note(id: String) -> String:
	return story(String((ZH.CLUE_NOTE if zh() else CLUE_NOTE).get(id, "")))


func doc(id: String) -> Array:
	var out := []
	for ln in (ZH.DOCS if zh() else DOCS).get(id, []):
		out.append(story(String(ln)))
	return out


func doc_title(id: String) -> String:
	return String((ZH.DOC_TITLE if zh() else DOC_TITLE).get(id, ""))


func credits() -> Array:
	return ZH.CREDITS if zh() else CREDITS


func body(n: String) -> String:
	if zh():
		return String(ZH.BODIES.get(n, n))
	return String(BODIES.get(n, n))
