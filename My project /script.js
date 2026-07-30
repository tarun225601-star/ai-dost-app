// 1. वॉइस (Speech Recognition) वाला कोड
function startListening() {
    const recognition = new (window.SpeechRecognition || window.webkitSpeechRecognition)();
    recognition.lang = 'hi-IN'; // हिंदी के लिए

    recognition.onresult = function(event) {
        const spokenText = event.results[0][0].transcript;
        console.log("आपने कहा: ", spokenText);
        document.getElementById('output').innerText = "आपने कहा: " + spokenText;
    };

    recognition.start();
}

// 2. API की सेटिंग और कॉल करने वाला कोड
const CONFIG = {
    API_KEY: "YOUR_API_KEY_HERE", // यहाँ अपनी असली एपीआई की डालें
    API_URL: "https://api.yourdomain.com/v1" // यहाँ अपना एपीआई यूआरएल डालें
};

async function callApi(promptText) {
    try {
        const response = await fetch(CONFIG.API_URL, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${CONFIG.API_KEY}`
            },
            body: JSON.stringify({ prompt: promptText })
        });
        return await response.json();
    } catch (error) {
        console.error("एरर आ गया:", error);
    }
}
