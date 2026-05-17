'use client'

import React, { useEffect, useState } from 'react'
import styles from './Footer.module.css'

interface FooterProps {
  className?: string
  initialBlur?: number
  animationDuration?: number
  animationDelay?: number
}

const Footer: React.FC<FooterProps> = ({
  className = '',
  initialBlur = 20,
  animationDuration = 2,
  animationDelay = 0.5,
}) => {
  const [isVisible, setIsVisible] = useState(false)

  useEffect(() => {
    const timer = setTimeout(() => {
      setIsVisible(true)
    }, animationDelay * 1000)
    return () => clearTimeout(timer)
  }, [animationDelay])

  return (
    <footer className={`${styles.footer} ${className}`}>
      <div className={styles.container}>
        <div className={styles.topSection}>
          <div className={styles.brandSection}>
            <div className={styles.brandTitle}>
              THE SWIFT
              <br />
              AI SDK
            </div>
          </div>

          <div className={styles.navColumn}>
            <a href="/docs" className={styles.navLink}>Documentation</a>
            <a href="/docs/quickstart" className={styles.navLink}>Quickstart</a>
            <a href="/docs/installation" className={styles.navLink}>Installation</a>
            <a href="/docs/providers" className={styles.navLink}>Providers</a>
            <a href="/docs/tool-calling" className={styles.navLink}>Tool Calling</a>
          </div>

          <div className={styles.navColumn}>
            <a href="https://github.com/Kartikayy007/SwiftyAI" className={styles.navLink}>GitHub</a>
            <a href="#" className={styles.navLink}>Discord</a>
            <a href="#" className={styles.navLink}>Support</a>
          </div>
        </div>

        <div
          className={styles.brandLarge}
          style={{
            filter: isVisible ? 'blur(0px)' : `blur(${initialBlur}px)`,
            transition: `filter ${animationDuration}s cubic-bezier(0.4, 0, 0.2, 1), transform ${animationDuration}s cubic-bezier(0.4, 0, 0.2, 1), opacity ${animationDuration}s cubic-bezier(0.4, 0, 0.2, 1)`,
            transform: isVisible ? 'scale(1)' : 'scale(0.95)',
            opacity: isVisible ? 1 : 0.3,
          }}
        >
          SWIFTY AI
        </div>

        <div className={styles.bottomBar}>
          <div className={styles.socialLinks}>
            <a href="#" className={styles.socialLink}>Twitter</a>
            <a href="#" className={styles.socialLink}>YouTube</a>
            <a href="#" className={styles.socialLink}>LinkedIn</a>
          </div>

          <div className={styles.legalLinks}>
            <a href="#" className={styles.legalLink}>Credits</a>
            <a href="#" className={styles.legalLink}>Privacy Policy</a>
            <a href="#" className={styles.legalLink}>MIT License</a>
          </div>
        </div>
      </div>
    </footer>
  )
}

export default Footer
