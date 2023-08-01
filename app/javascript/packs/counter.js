const timer = setInterval(() => {
  const currentClientTime = Math.floor(Date.now() / 1000);
  const timeLeft = serverTimeLeft - (currentClientTime - startClientTime);

  if (timeLeft <= 0) {
    clearInterval(timer);
    document.getElementById("timer").innerText = "00:00:00";
    //alert("Time's up! Test is finished.");
    // Xử lý khi hết giờ, ví dụ: submit form để gửi kết quả
    const submitButton = document.querySelector("#submit-test");
    submitButton.click();
  } else {
    const hours = Math.floor(timeLeft / 3600);
    const minutes = Math.floor((timeLeft % 3600) / 60);
    const seconds = timeLeft % 60;
    const formattedTime = `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
    document.getElementById("timer").innerText = formattedTime;
  }
}, 1000)
