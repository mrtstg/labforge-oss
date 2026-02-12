document.addEventListener('DOMContentLoaded', () => {
  const navbar = document.getElementById('navBurger')
  navbar.addEventListener('click', () => {
    const target = document.getElementById('navMenu')
    navbar.classList.toggle('is-active')
    target.classList.toggle('is-active')
  })
  var dropdown = document.querySelector('.dropdown');
  dropdown.addEventListener('click', function(event) {
     event.stopPropagation();
     dropdown.classList.toggle('is-active');
  });
});
