const questionTypeSelect = document.getElementById('question_question_type');
const answersDiv = document.getElementById('answers');

// Khi chọn single_choice thì chuyển về 1 checkbox
questionTypeSelect.addEventListener('change', e => {
    const checkboxes = document.querySelectorAll('input[type=checkbox]');
    if (e.target.value === 'single_choice') {
        checkboxes.forEach(checkbox => checkbox.checked = false);
        checkboxes[0].checked = true;
    }
})

// Listen event từ parent
answersDiv.addEventListener('change', e => {
    if (e.target.type === 'checkbox') {
        handleChange(e.target);
    }
})

// Khi chọn option thì xóa các option khác
const handleChange = (checkbox) => {
    if (questionTypeSelect.value === 'single_choice') {
        const checkboxes = document.querySelectorAll('input[type=checkbox]');
        checkboxes.forEach(checkbox => checkbox.checked = false);
        checkbox.checked = true;
    }
}
