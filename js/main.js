/* ============================================================
   AgentTask — Main JavaScript
   Navigation, animations, interactions, i18n
   ============================================================ */

document.addEventListener('DOMContentLoaded', () => {
  initLangSwitch();
  initNav();
  initScrollAnimations();
  initEndpointToggles();
  initTaskFilters();
  initMobileMenu();
  initFormValidation();
  initCopyButtons();
  initTerminalTyping();
  initContactForm();
  animateCounters();
});

/* ---------- Language Switcher ---------- */
function initLangSwitch() {
  const saved = localStorage.getItem('agenttask-lang') || 'ja';
  setLang(saved);

  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      setLang(btn.dataset.lang);
    });
  });
}

function setLang(lang) {
  document.documentElement.lang = lang;
  localStorage.setItem('agenttask-lang', lang);

  document.querySelectorAll('.lang-btn').forEach(btn => {
    btn.classList.toggle('active', btn.dataset.lang === lang);
  });
}

/* ---------- Navigation scroll effect ---------- */
function initNav() {
  const nav = document.querySelector('.nav');
  if (!nav) return;

  const onScroll = () => {
    nav.classList.toggle('scrolled', window.scrollY > 20);
  };
  window.addEventListener('scroll', onScroll, { passive: true });
  onScroll();

  // Active link highlighting
  const links = document.querySelectorAll('.nav-links a');
  const currentPage = window.location.pathname.split('/').pop() || 'index.html';
  links.forEach(link => {
    const href = link.getAttribute('href');
    if (href === currentPage || (currentPage === '' && href === 'index.html')) {
      link.classList.add('active');
    }
  });
}

/* ---------- Scroll-triggered fade-in ---------- */
function initScrollAnimations() {
  const elements = document.querySelectorAll('.fade-in');
  if (!elements.length) return;

  const observer = new IntersectionObserver((entries) => {
    entries.forEach((entry, index) => {
      if (entry.isIntersecting) {
        setTimeout(() => {
          entry.target.classList.add('visible');
        }, index * 80);
        observer.unobserve(entry.target);
      }
    });
  }, { threshold: 0.1, rootMargin: '0px 0px -40px 0px' });

  elements.forEach(el => observer.observe(el));
}

/* ---------- API endpoint toggles ---------- */
function initEndpointToggles() {
  document.querySelectorAll('.endpoint-header').forEach(header => {
    header.addEventListener('click', () => {
      const body = header.nextElementSibling;
      if (body && body.classList.contains('endpoint-body')) {
        body.classList.toggle('open');
        header.classList.toggle('open');
      }
    });
  });
}

/* ---------- Task filter buttons ---------- */
function initTaskFilters() {
  const filters = document.querySelectorAll('.filter-btn');
  const tasks = document.querySelectorAll('.task-card');

  filters.forEach(btn => {
    btn.addEventListener('click', () => {
      filters.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const category = btn.dataset.filter;
      tasks.forEach(task => {
        if (category === 'all' || task.dataset.category === category) {
          task.style.display = '';
          task.style.opacity = '0';
          task.style.transform = 'translateY(10px)';
          requestAnimationFrame(() => {
            task.style.transition = 'opacity .3s, transform .3s';
            task.style.opacity = '1';
            task.style.transform = 'translateY(0)';
          });
        } else {
          task.style.display = 'none';
        }
      });
    });
  });
}

/* ---------- Mobile menu ---------- */
function initMobileMenu() {
  const toggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('.nav-links');
  if (!toggle || !links) return;

  toggle.addEventListener('click', () => {
    links.classList.toggle('open');
    toggle.textContent = links.classList.contains('open') ? '\u2715' : '\u2630';
  });

  links.querySelectorAll('a').forEach(link => {
    link.addEventListener('click', () => {
      links.classList.remove('open');
      toggle.textContent = '\u2630';
    });
  });
}

/* ---------- Form validation ---------- */
function initFormValidation() {
  const forms = document.querySelectorAll('.register-form, .contact-form');
  forms.forEach(form => {
    form.addEventListener('submit', (e) => {
      e.preventDefault();

      const requiredFields = form.querySelectorAll('[required]');
      let valid = true;

      requiredFields.forEach(field => {
        field.style.borderColor = '';
        if (!field.value.trim()) {
          field.style.borderColor = 'var(--accent-pink)';
          valid = false;
        }
      });

      if (valid) {
        const btn = form.querySelector('.btn-primary');
        const lang = document.documentElement.lang;
        const originalText = btn.textContent;
        btn.textContent = lang === 'ja' ? '\u9001\u4fe1\u5b8c\u4e86\uff01' : 'Sent!';
        btn.style.background = 'var(--accent-green)';
        btn.disabled = true;

        setTimeout(() => {
          btn.textContent = originalText;
          btn.style.background = '';
          btn.disabled = false;
          form.reset();
          // Reset contact type selection
          document.querySelectorAll('.contact-type-card').forEach(c => c.classList.remove('selected'));
        }, 3000);
      }
    });
  });
}

/* ---------- Contact form type selection ---------- */
function initContactForm() {
  document.querySelectorAll('.contact-type-card').forEach(card => {
    card.addEventListener('click', () => {
      document.querySelectorAll('.contact-type-card').forEach(c => c.classList.remove('selected'));
      card.classList.add('selected');
      const radio = card.querySelector('input[type="radio"]');
      if (radio) radio.checked = true;
    });
  });
}

/* ---------- Copy code buttons ---------- */
function initCopyButtons() {
  document.querySelectorAll('.copy-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      const codeBlock = btn.closest('.code-block');
      const code = codeBlock.querySelector('code');
      if (!code) return;

      const text = code.textContent;
      navigator.clipboard.writeText(text).then(() => {
        const original = btn.textContent;
        btn.textContent = 'Copied!';
        btn.style.color = 'var(--accent-green)';
        btn.style.borderColor = 'var(--accent-green)';
        setTimeout(() => {
          btn.textContent = original;
          btn.style.color = '';
          btn.style.borderColor = '';
        }, 2000);
      });
    });
  });
}

/* ---------- Terminal typing effect ---------- */
function initTerminalTyping() {
  const terminals = document.querySelectorAll('.terminal-typing');
  terminals.forEach(terminal => {
    const text = terminal.dataset.text || '';
    const speed = parseInt(terminal.dataset.speed) || 40;
    terminal.textContent = '';
    let i = 0;

    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        const type = () => {
          if (i < text.length) {
            terminal.textContent += text.charAt(i);
            i++;
            setTimeout(type, speed);
          }
        };
        type();
        observer.unobserve(terminal);
      }
    }, { threshold: 0.5 });

    observer.observe(terminal);
  });
}

/* ---------- Smooth scroll for anchor links ---------- */
document.addEventListener('click', (e) => {
  const link = e.target.closest('a[href^="#"]');
  if (!link) return;

  const target = document.querySelector(link.getAttribute('href'));
  if (target) {
    e.preventDefault();
    target.scrollIntoView({ behavior: 'smooth', block: 'start' });
  }
});

/* ---------- Counter animation ---------- */
function animateCounters() {
  document.querySelectorAll('.counter').forEach(counter => {
    const target = parseInt(counter.dataset.target);
    const suffix = counter.dataset.suffix || '';
    const duration = 2000;
    const start = performance.now();

    const update = (now) => {
      const elapsed = now - start;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3);
      counter.textContent = Math.floor(target * eased).toLocaleString() + suffix;

      if (progress < 1) {
        requestAnimationFrame(update);
      }
    };

    const observer = new IntersectionObserver((entries) => {
      if (entries[0].isIntersecting) {
        requestAnimationFrame(update);
        observer.unobserve(counter);
      }
    }, { threshold: 0.5 });

    observer.observe(counter);
  });
}
