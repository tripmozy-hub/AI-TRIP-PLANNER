
//#region app.js
document.addEventListener("DOMContentLoaded", () => {
	lucide.createIcons();
	setupEventListeners();
	const savedKey = localStorage.getItem("tripmozy_gemini_key");
	if (savedKey) {
		const input = document.getElementById("geminiApiKeyInput");
		if (input) input.value = savedKey;
	}
});
function setupEventListeners() {
	document.querySelectorAll(".chip").forEach((chip) => {
		chip.addEventListener("click", () => {
			const group = chip.getAttribute("data-group");
			document.querySelectorAll(`.chip[data-group="${group}"]`).forEach((c) => {
				c.classList.remove("active");
				const radio = c.querySelector("input[type=\"radio\"]");
				if (radio) radio.checked = false;
			});
			chip.classList.add("active");
			const radio = chip.querySelector("input[type=\"radio\"]");
			if (radio) radio.checked = true;
		});
	});
	document.querySelectorAll(".interest-chip").forEach((chip) => {
		chip.addEventListener("click", () => {
			chip.classList.toggle("active");
			if (chip.classList.contains("active")) chip.className = "interest-chip active px-3.5 py-1.5 rounded-lg text-xs sm:text-sm font-medium border border-blue-600 bg-blue-600 text-white flex items-center gap-1.5 shadow-sm transition";
			else chip.className = "interest-chip px-3.5 py-1.5 rounded-lg text-xs sm:text-sm font-medium border border-slate-300 bg-white text-slate-700 hover:border-slate-400 flex items-center gap-1.5 transition";
		});
	});
}

//#endregion