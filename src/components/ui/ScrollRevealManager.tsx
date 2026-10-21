import { useEffect } from 'react'
import { useLocation } from 'react-router-dom'

/**
 * ScrollRevealManager
 * High-performance, disciplined scroll motion system using IntersectionObserver.
 * Observes elements with .reveal-on-scroll, .reveal-text, .reveal-card, .reveal-stat, .reveal-scale, .reveal-badge
 * and activates their .is-revealed state smoothly as the user scrolls into view.
 */
export function ScrollRevealManager() {
  const { pathname } = useLocation()

  useEffect(() => {
    // If user prefers reduced motion, reveal everything immediately
    const prefersReducedMotion =
      typeof window !== 'undefined' &&
      window.matchMedia('(prefers-reduced-motion: reduce)').matches

    if (prefersReducedMotion || typeof window === 'undefined' || !('IntersectionObserver' in window)) {
      document
        .querySelectorAll(
          '.reveal-on-scroll, .reveal-text, .reveal-card, .reveal-stat, .reveal-scale, .reveal-badge'
        )
        .forEach((el) => el.classList.add('is-revealed'))
      return
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add('is-revealed')
            observer.unobserve(entry.target)
          }
        })
      },
      {
        rootMargin: '100px 0px 100px 0px',
        threshold: 0.01,
      }
    )

    const attachObservers = () => {
      const vh = window.innerHeight || document.documentElement.clientHeight || 800
      const elements = document.querySelectorAll(
        '.reveal-on-scroll, .reveal-text, .reveal-card, .reveal-stat, .reveal-scale, .reveal-badge'
      )
      elements.forEach((el) => {
        const rect = el.getBoundingClientRect()
        // If element is already within or near the viewport, reveal smoothly
        if (rect.top <= vh + 80) {
          el.classList.add('is-revealed')
        } else if (!el.classList.contains('is-revealed')) {
          observer.observe(el)
        }
      })
    }

    // Initial check after paint
    const timer = setTimeout(attachObservers, 40)
    const timer2 = setTimeout(attachObservers, 250)

    // Fallback: after 800ms reveal any remaining observed elements so nothing stays hidden
    const timer3 = setTimeout(() => {
      document
        .querySelectorAll(
          '.reveal-on-scroll, .reveal-text, .reveal-card, .reveal-stat, .reveal-scale, .reveal-badge'
        )
        .forEach((el) => el.classList.add('is-revealed'))
    }, 800)

    // MutationObserver to observe newly rendered dynamic components
    const mutObserver = new MutationObserver(() => {
      attachObservers()
    })

    mutObserver.observe(document.body, { childList: true, subtree: true })

    return () => {
      clearTimeout(timer)
      clearTimeout(timer2)
      clearTimeout(timer3)
      observer.disconnect()
      mutObserver.disconnect()
    }
  }, [pathname])

  return null
}
