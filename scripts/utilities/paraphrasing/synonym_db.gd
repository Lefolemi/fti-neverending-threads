class_name SynonymDB extends RefCounted

# The Master Dictionary of "Safe Swaps"
# Keys are lowercase. Values are arrays of replacements.
const DICTIONARY = {
	# --- CONJUNCTIONS (Kata Sambung) ---
	"misalnya": ["misalnya", "contohnya"],
	"contohnya": ["contohnya", "misalnya"],
	"dan": ["serta", "beserta"],
	"atau": ["ataupun"],
	"tetapi": ["tapi", "namun", "akan tetapi"],
	"karena": ["sebab", "dikarenakan", "lantaran"],
	"jika": ["kalau", "apabila", "bila", "seandainya"],
	"agar": ["supaya", "biar"],
	"seperti": ["bagai", "laksana", "semisal", "contohnya"],
	"yaitu": ["yakni", "adalah", "ialah"],
	"maka": ["lantas", "hasilnya"],
	"walaupun": ["meskipun", "kendati", "biarpun"],
	"sebelum": ["jelang", "mendahului"],
	"sesudah": ["setelah", "pasca", "usai"],
	"saat": ["ketika", "waktu", "tatkala", "selama", "pas"],
	"sambil": ["sembari", "seraya"],

	# --- VERBS (Kata Kerja Umum) ---
	"menggunakan": ["memakai", "memanfaatkan", "mengaplikasikan"],
	"membuat": ["menciptakan", "menyusun", "membangun", "membikin"],
	"melihat": ["memandang", "menengok", "menyaksikan"],
	"mendapatkan": ["memperoleh", "meraih", "menggapai"],
	"memberikan": ["menyediakan", "menyerahkan", "menyajikan"],
	"mengubah": ["mengganti", "memodifikasi", "menukar"],
	"memilih": ["menyeleksi", "menentukan", "mengambil"],
	"menjelaskan": ["menerangkan", "menguraikan", "memaparkan"],
	"bertanya": ["menanyakan"],
	"menjawab": ["merespons", "menanggapi"],
	"berhenti": ["stop", "diam", "mandek"],
	"mulai": ["awali", "start"],
	"mencari": ["menelusuri", "memburu"],
	"memerlukan": ["membutuhkan", "perlu", "butuh"],

	# --- NOUNS / ABSTRACT CONCEPTS (Kata Benda Abstrak) ---
	"masalah": ["persoalan", "kendala", "hambatan", "problem", "isu"],
	"tujuan": ["maksud", "sasaran", "target", "gol", "arah"],
	"cara": ["metode", "teknik", "langkah", "prosedur", "mekanisme"],
	"hasil": ["konsekuensinya", "dampaknya", "output"],
	"contoh": ["misal", "sampel", "teladan", "ilustrasi"],
	"bagian": ["segmen", "sektor", "unsur", "elemen", "komponen"],
	"jenis": ["tipe", "macam", "ragam", "bentuk", "kategori"],
	"jumlah": ["kuantitas", "total", "banyaknya"],
	"tempat": ["lokasi", "posisi", "letak", "area", "kawasan"],
	"waktu": ["masa", "kala", "tempo", "durasi", "periode"],
	"manusia": ["orang", "insan", "individu", "person"],
	"kelompok": ["grup", "tim", "regu", "komunitas"],
	"data": ["informasi", "fakta", "keterangan"],
	"alat": ["perangkat", "instrumen", "sarana", "media"],

	# --- ADJECTIVES (Kata Sifat) ---
	"besar": ["luas", "akbar", "raksasa", "masif"],
	"kecil": ["mini", "mikro", "sempit", "sedikit"],
	"banyak": ["beragam", "sejumlah", "berlimpah"],
	"penting": ["krusial", "signifikan", "utama", "pokok"],
	"benar": ["betul", "tepat", "akurat", "sahih"],
	"salah": ["keliru", "meleset", "tidak tepat"],
	"sama": ["serupa", "identik", "mirip"],
	"beda": ["lain", "berlainan"],
	"cepat": ["lekas", "kilat", "gesit", "segera"],
	"lambat": ["pelan", "lelet"],
	"sulit": ["susah", "sukar", "rumit", "kompleks"],
	"mudah": ["gampang", "simpel", "enteng"],
	"sering": ["kerap", "acapkali", "berulang kali"],
	"jarang": ["langka"],
	"selalu": ["senantiasa", "terus-menerus"],

	# --- ADVERBS / MISC (Kata Keterangan) ---
	"sangat": ["amat", "sungguh", "luar biasa"],
	"hanya": ["cuma", "sekadar", "semata-mata"],
	"hampir": ["nyaris", "mendekati"],
	"mungkin": ["barangkali", "boleh jadi", "bisa jadi"],
	"pasti": ["tentu", "niscaya", "sudah tentu"],
	"kira-kira": ["kurang lebih", "sekitar", "estimasi"],
	"secara": ["lewat", "melalui"],
	"oleh": ["akibat", "lantaran"]
}

# --------------------------------------------------------------------------
# FUNCTION: Inject Synonyms
# --------------------------------------------------------------------------
static func inject_synonyms(text: String, chance: float = 0.3) -> String:
	# 1. Simple split by space.
	var words = text.split(" ")
	var new_words = []
	
	for word in words:
		# A. Clean the word (strip punctuation like comma, dot, question mark)
		var clean_word = word.to_lower().strip_edges()
		var punctuation = ""
		
		# Check suffix punctuation (.,?!:;)
		if clean_word.length() > 0 and clean_word[-1] in [",", ".", "?", "!", ":", ";"]:
			punctuation = clean_word[-1]
			clean_word = clean_word.left(-1)
			
		# Check prefix punctuation (parenthesis, quotes)
		var prefix = ""
		if clean_word.length() > 0 and clean_word[0] in ["(", "\"", "'"]:
			prefix = clean_word[0]
			clean_word = clean_word.right(-1)

		# B. Check Database
		if clean_word in DICTIONARY:
			# Roll the dice
			if randf() < chance:
				# 1. Duplicate the synonym list so we don't mess up the const
				var candidates = DICTIONARY[clean_word].duplicate()
				
				# 2. Add the ORIGINAL word to the pool!
				candidates.append(clean_word)
				
				# 3. Pick from the combined pool
				var replacement = candidates[randi() % candidates.size()]
				
				# C. Restore Capitalization
				if word[0] == word[0].to_upper() and word[0] != word[0].to_lower():
					# Check if ALL caps (e.g. MAKA)
					if word == word.to_upper():
						replacement = replacement.to_upper()
					else:
						# Just Title Case (e.g. Maka)
						replacement = replacement.capitalize()
				
				new_words.append(prefix + replacement + punctuation)
			else:
				new_words.append(word) # Chance check failed, keep original
		else:
			new_words.append(word) # Not in DB
			
	return " ".join(new_words)
