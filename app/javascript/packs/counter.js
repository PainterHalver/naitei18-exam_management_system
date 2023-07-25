function updateCountdown() {
  const currentTime = Math.floor(Date.now() / 1000);
  const timeLeft = endTime - currentTime;

  if (timeLeft <= 0) {
    document.getElementById("timer").innerText = "00:00";
    alert("Time's up! Test is finished.");
    // Xử lý khi hết giờ, ví dụ: submit form để gửi kết quả
  } else {
    const hours = Math.floor(timeLeft / 3600);
    const minutes = Math.floor((timeLeft % 3600) / 60);
    const seconds = timeLeft % 60;
    const formattedTime =
    `${hours.toString().padStart(2, "0")}:${minutes.toString().padStart(2, "0")}:${seconds.toString().padStart(2, "0")}`;
    document.getElementById("timer").innerText = formattedTime;
  }
}
setInterval(updateCountdown, 1000);
