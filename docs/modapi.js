(() => {
  const search = document.querySelector('#doc-search');
  const status = document.querySelector('#search-status');
  const docsColumn = document.querySelector('.docs-column');
  const chapterOrder = [
    'overview', 'song-list', 'characters', 'stages', 'weeks', 'scripts', 'assets',
    'quickstart', 'structure', 'manifest', 'zip-mods', 'mod-library', 'troubleshooting'
  ];
  const chapterFooter = docsColumn.querySelector('.doc-footer');
  for (const sectionId of chapterOrder) {
    const section = document.getElementById(sectionId);
    if (section) docsColumn.insertBefore(section, chapterFooter);
  }
  const sections = chapterOrder.map((sectionId) => document.getElementById(sectionId)).filter(Boolean);
  const tocLinks = [...document.querySelectorAll('.toc-link')];
  const progress = document.querySelector('#reading-progress');
  const menuButton = document.querySelector('#mobile-menu');
  const scrim = document.querySelector('#sidebar-scrim');
  const sectionIds = new Set(sections.map((section) => section.id));
  const sectionNames = new Map(tocLinks.map((link) => [link.hash.slice(1), link.textContent.trim().replace(/^\d+\s*/, '')]));
  let activeSectionId = sectionIds.has(location.hash.slice(1)) ? location.hash.slice(1) : 'overview';

  function createChapterLink(sectionId, direction) {
    const link = document.createElement('a');
    link.className = `chapter-link chapter-${direction}`;
    link.href = `#${sectionId}`;
    const caption = document.createElement('small');
    caption.textContent = direction === 'previous' ? 'PREVIOUS CHAPTER' : 'NEXT CHAPTER';
    const title = document.createElement('strong');
    title.textContent = sectionNames.get(sectionId) || sectionId;
    link.append(caption, title);
    return link;
  }

  sections.forEach((section, index) => {
    const pager = document.createElement('nav');
    pager.className = 'chapter-nav';
    pager.setAttribute('aria-label', 'Chapter navigation');

    if (index > 0) pager.append(createChapterLink(sections[index - 1].id, 'previous'));
    else pager.append(document.createElement('span'));

    const count = document.createElement('span');
    count.className = 'chapter-count';
    count.textContent = `${String(index + 1).padStart(2, '0')} / ${String(sections.length).padStart(2, '0')}`;
    pager.append(count);

    if (index < sections.length - 1) pager.append(createChapterLink(sections[index + 1].id, 'next'));
    else pager.append(document.createElement('span'));

    section.append(pager);
  });

  function showSection(sectionId, pushHistory = true, scrollToTop = true) {
    if (!sectionIds.has(sectionId)) return;
    activeSectionId = sectionId;

    for (const section of sections) {
      section.hidden = section.id !== sectionId;
    }
    for (const link of tocLinks) {
      const isActive = link.hash === `#${sectionId}`;
      link.classList.toggle('active', isActive);
      if (isActive) link.setAttribute('aria-current', 'page');
      else link.removeAttribute('aria-current');
    }

    if (pushHistory && location.hash !== `#${sectionId}`) {
      history.pushState({ section: sectionId }, '', `#${sectionId}`);
    }
    if (scrollToTop) window.scrollTo({ top: 0, behavior: 'smooth' });
    updateProgress();
    closeMenu();
  }

  function filterDocs() {
    const query = search.value.trim().toLowerCase();
    const matches = sections.filter((section) =>
      `${section.dataset.search || ''} ${section.textContent}`.toLowerCase().includes(query)
    );

    for (const link of tocLinks) {
      link.hidden = Boolean(query) && !matches.some((section) => `#${section.id}` === link.hash);
    }

    if (query && matches.length === 0) {
      status.textContent = 'No matching chapters.';
      for (const section of sections) section.hidden = true;
      return;
    }

    if (query) {
      status.textContent = `${matches.length} matching ${matches.length === 1 ? 'chapter' : 'chapters'}.`;
      showSection(matches[0].id, false, false);
      return;
    }

    status.textContent = '';
    showSection(activeSectionId, false, false);
  }

  search.addEventListener('input', filterDocs);
  document.addEventListener('keydown', (event) => {
    if ((event.metaKey || event.ctrlKey) && event.key.toLowerCase() === 'k') {
      event.preventDefault();
      search.focus();
    }
    if (event.key === 'Escape') {
      search.value = '';
      filterDocs();
      search.blur();
      closeMenu();
    }
  });

  document.addEventListener('click', async (event) => {
    const sectionLink = event.target.closest('.toc-link, .chapter-link, .intro-actions a, .brand');
    if (sectionLink && sectionIds.has(sectionLink.hash.slice(1))) {
      event.preventDefault();
      if (search.value) {
        search.value = '';
        filterDocs();
      }
      showSection(sectionLink.hash.slice(1));
      return;
    }

    const button = event.target.closest('[data-copy]');
    if (!button) return;

    const code = document.getElementById(button.dataset.copy);
    if (!code) return;
    const text = code.textContent;

    try {
      await navigator.clipboard.writeText(text);
    } catch {
      const range = document.createRange();
      range.selectNodeContents(code);
      const selection = window.getSelection();
      selection.removeAllRanges();
      selection.addRange(range);
      document.execCommand('copy');
      selection.removeAllRanges();
    }

    button.textContent = 'Copied';
    button.classList.add('copied');
    window.setTimeout(() => {
      button.textContent = 'Copy';
      button.classList.remove('copied');
    }, 1300);
  });

  function updateProgress() {
    const maxScroll = document.documentElement.scrollHeight - window.innerHeight;
    const percent = maxScroll > 0 ? (window.scrollY / maxScroll) * 100 : 0;
    progress.style.width = `${percent}%`;
  }

  window.addEventListener('scroll', updateProgress, { passive: true });
  window.addEventListener('resize', updateProgress);
  window.addEventListener('popstate', () => {
    const requestedSection = location.hash.slice(1);
    showSection(sectionIds.has(requestedSection) ? requestedSection : 'overview', false);
  });
  updateProgress();

  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver((entries) => {
      const current = entries
        .filter((entry) => entry.isIntersecting)
        .sort((a, b) => b.intersectionRatio - a.intersectionRatio)[0];
      if (!current) return;
      for (const link of tocLinks) {
        link.classList.toggle('active', link.hash === `#${current.target.id}`);
      }
    }, { rootMargin: '-18% 0px -68% 0px', threshold: [0, 0.2, 0.5] });

    sections.forEach((section) => observer.observe(section));
  }

  function closeMenu() {
    document.body.classList.remove('menu-open');
    menuButton.setAttribute('aria-expanded', 'false');
  }

  menuButton.addEventListener('click', () => {
    const isOpen = document.body.classList.toggle('menu-open');
    menuButton.setAttribute('aria-expanded', String(isOpen));
  });
  scrim.addEventListener('click', closeMenu);
  tocLinks.forEach((link) => link.addEventListener('click', closeMenu));
  showSection(activeSectionId, false, false);
  filterDocs();
})();
