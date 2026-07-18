/* ==========================================================================
   SERGAK LANDING PAGE - DYNAMIC INTERACTIVE JAVASCRIPT
   Mockup Tab Switching, Custom Active Scan Simulator, Responsive Navbar
   ========================================================================== */

document.addEventListener('DOMContentLoaded', () => {

  // 1. NAVBAR SCROLL EFFECT
  const navbar = document.getElementById('navbar');
  window.addEventListener('scroll', () => {
    if (window.scrollY > 50) {
      navbar.classList.add('scrolled');
    } else {
      navbar.classList.remove('scrolled');
    }
  });

  // 2. RESPONSIVE BURGER MENU
  const burger = document.getElementById('burger');
  const navLinks = document.getElementById('navLinks');

  burger.addEventListener('click', () => {
    navLinks.classList.toggle('active');
    burger.classList.toggle('active');
  });

  // Close mobile menu when a link is clicked
  const navItems = navLinks.querySelectorAll('a');
  navItems.forEach(item => {
    item.addEventListener('click', () => {
      navLinks.classList.remove('active');
      burger.classList.remove('active');
    });
  });

  // 3. INTERACTIVE MOCKUP TAB CHANGER
  const tabButtons = document.querySelectorAll('.phone-tab-btn');
  const simScreens = document.querySelectorAll('.sim-screen');

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      // Deactivate all buttons
      tabButtons.forEach(b => b.classList.remove('active'));
      // Activate clicked button
      btn.classList.add('active');

      // Get target screen ID
      const targetId = btn.getAttribute('data-target');

      // Switch screens with CSS transitions
      simScreens.forEach(screen => {
        if (screen.id === targetId) {
          screen.classList.add('active');
        } else {
          screen.classList.remove('active');
        }
      });
    });
  });

  // 4. RADAR SIMULATOR SCAN CONTROLLER
  const scanAppsBtn = document.getElementById('demoScanApps');
  const scanSmsBtn = document.getElementById('demoScanSms');
  const secureVaultBtn = document.getElementById('demoSecureVault');
  
  const demoRadar = document.getElementById('demoRadar');
  const demoPercent = document.getElementById('demoPercent');
  const demoResult = document.getElementById('demoResult');
  
  let scanInterval = null;

  function runSimulatorScan(type, startMsg, endMsg) {
    // Reset any ongoing scan
    clearInterval(scanInterval);
    demoPercent.textContent = '0%';
    demoResult.innerHTML = `<span style="color: var(--cyan)">⌛ ${startMsg}...</span>`;
    
    // Add active animation class to radar
    demoRadar.classList.add('active-scanning');
    
    let percent = 0;
    scanInterval = setInterval(() => {
      percent += Math.floor(Math.random() * 8) + 4;
      if (percent >= 100) {
        percent = 100;
        clearInterval(scanInterval);
        demoRadar.classList.remove('active-scanning');
        demoResult.innerHTML = `<span style="color: var(--primary); font-weight: 700;">🚀 ${endMsg}</span>`;
      }
      demoPercent.textContent = `${percent}%`;
    }, 100);
  }

  // Event Listeners for Simulator Buttons
  scanAppsBtn.addEventListener('click', () => {
    setActiveSimulatorButton(scanAppsBtn);
    runSimulatorScan(
      'apps', 
      'Telefondagi barcha o\'rnatilgan ilovalar va yashirin ruxsatlar tekshirilmoqda',
      'Tahlil yakunlandi! 14 ta ilova tekshirildi. 1 ta xavfli ilova topildi (Music Player). Shubhali ruxsatlar bloklandi!'
    );
  });

  scanSmsBtn.addEventListener('click', () => {
    setActiveSimulatorButton(scanSmsBtn);
    runSimulatorScan(
      'sms', 
      'Fonda kelayotgan SMS xabarlar va kalit so\'zlar AI tomonidan tahlil qilinmoqda',
      'Xavfsizlik tasdiqlandi! 3 ta SMS o\'rganildi. 1 ta phishing fishing havolasi va firibgarlik kodi aniqlandi va bloklandi!'
    );
  });

  secureVaultBtn.addEventListener('click', () => {
    setActiveSimulatorButton(secureVaultBtn);
    runSimulatorScan(
      'vault', 
      'AES-256 harbiy shifrlash kalitlari generatsiya qilinmoqda',
      'Seyf faol! Barcha tanlangan shaxsiy rasmlar va maxfiy hujjatlar qurilmaning o\'zida oflayn tarzda to\'liq shifrlangan holatda yashirildi.'
    );
  });

  function setActiveSimulatorButton(activeBtn) {
    const actionBtns = document.querySelectorAll('.btn-demo-action');
    actionBtns.forEach(btn => btn.classList.remove('active'));
    activeBtn.classList.add('active');
  }

  // 5. PHONE MOCKUP SMART SCAN CLICK REDIRECT
  const smartScanBtn = document.querySelector('.btn-smart-scan');
  const protectionTabBtn = document.querySelector('.phone-tab-btn[data-target="screen-protection"]');

  if (smartScanBtn) {
    smartScanBtn.addEventListener('click', () => {
      smartScanBtn.textContent = 'Skanerlanmoqda... ⚡';
      smartScanBtn.style.background = '#00C853';
      smartScanBtn.style.color = 'white';
      
      setTimeout(() => {
        smartScanBtn.textContent = 'Xavfsiz! ✔';
        smartScanBtn.style.background = '#00E676';
        
        // Auto navigate to Protection (Himoya) screen after scan
        setTimeout(() => {
          if (protectionTabBtn) {
            protectionTabBtn.click();
          }
          // Reset button back to original state
          smartScanBtn.textContent = 'Smart Scan';
          smartScanBtn.style.background = 'white';
          smartScanBtn.style.color = '#00C853';
        }, 800);
      }, 1200);
    });
  }

  // 6. LIVE SMART PHONE CHATBOT SIMULATION
  const chatInput = document.querySelector('.sim-chat-input');
  const chatSendBtn = document.querySelector('.btn-sim-send');
  const chatContainer = document.querySelector('.sim-chat-container');

  if (chatInput) {
    // Enable the input for interaction!
    chatInput.removeAttribute('disabled');

    const handleSendMessage = () => {
      const text = chatInput.value.trim();
      if (!text) return;

      // Append User message
      const userBubble = document.createElement('div');
      userBubble.className = 'chat-bubble user';
      userBubble.style.background = '#00E676';
      userBubble.style.color = 'white';
      userBubble.style.alignSelf = 'flex-end';
      userBubble.style.marginTop = '10px';
      userBubble.style.borderRadius = '16px 16px 4px 16px';
      userBubble.textContent = text;
      
      chatContainer.appendChild(userBubble);
      chatContainer.scrollTop = chatContainer.scrollHeight;
      chatInput.value = '';

      // Auto Bot Response after short delay
      setTimeout(() => {
        // Typing placeholder
        const botTypingBubble = document.createElement('div');
        botTypingBubble.className = 'chat-bubble bot';
        botTypingBubble.style.marginTop = '10px';
        botTypingBubble.textContent = 'Javob yozilmoqda... ⏳';
        chatContainer.appendChild(botTypingBubble);
        chatContainer.scrollTop = chatContainer.scrollHeight;

        setTimeout(() => {
          // Select smart AI response
          const botResponses = [
            "SERGAK AI: Smartfoningiz to'liq oflayn himoyada! Ruxsatnomalar tahlili va SMS monitoring doimiy ishlamoqda.",
            "SERGAK AI: Shubhali SMS havolalarini (fishing) ochmang. Ular sizning plastik kartangizni o'g'irlash uchun mo'ljallangan.",
            "SERGAK AI: Hech qachon shaxsiy Click/Payme parollarini va SMS kodlarini begonalarga taqdim etmang!",
            "SERGAK AI: Har qanday shubhali ilovani yuklashdan oldin unga beriladigan orqa fondagi ruxsatlarni tekshiring."
          ];
          const randomResponse = botResponses[Math.floor(Math.random() * botResponses.length)];
          botTypingBubble.textContent = randomResponse;
          chatContainer.scrollTop = chatContainer.scrollHeight;
        }, 1200);

      }, 500);
    };

    chatSendBtn.addEventListener('click', handleSendMessage);
    chatInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        handleSendMessage();
      }
    });
  }

  // 7 & 9. PRICING CARD & BUTTON INTERACTIVITY (UNIFIED)
  const pricingCards = document.querySelectorAll('.pricing-card');
  const paymentSection = document.getElementById('pricing-payment');
  const btnSelectPlans = document.querySelectorAll('.btn-pricing-select');
  const checkoutPlanName = document.getElementById('checkoutPlanName');
  const checkoutPlanPrice = document.getElementById('checkoutPlanPrice');
  const btnPayAmount = document.getElementById('btnPayAmount');

  function selectPlan(cardId) {
    // Reset all buttons
    btnSelectPlans.forEach(b => {
      b.textContent = 'Tanlash →';
      b.style.background = '';
      b.style.borderColor = 'rgba(255,255,255,0.1)';
    });

    if (cardId === 'plan1year') {
      const btn = document.querySelector('#plan1year .btn-pricing-select');
      if(btn) {
        btn.textContent = 'Tanlandi ✓';
        btn.style.background = '#00E676';
      }
      if(checkoutPlanName) checkoutPlanName.textContent = '1 Yillik Reja';
      if(checkoutPlanPrice) checkoutPlanPrice.textContent = "85,000 so'm";
      if(btnPayAmount) btnPayAmount.textContent = "85,000 so'm To'lash";
    } else {
      const btn = document.querySelector('#plan3month .btn-pricing-select');
      if(btn) {
        btn.textContent = 'Tanlandi ✓';
        btn.style.background = 'rgba(0, 230, 118, 0.2)';
        btn.style.borderColor = '#00E676';
      }
      if(checkoutPlanName) checkoutPlanName.textContent = '3 Oylik Reja';
      if(checkoutPlanPrice) checkoutPlanPrice.textContent = "25,000 so'm";
      if(btnPayAmount) btnPayAmount.textContent = "25,000 so'm To'lash";
    }

    // Show payment section
    paymentSection.style.display = 'block';
    setTimeout(() => {
      paymentSection.classList.add('animate-in');
      paymentSection.scrollIntoView({ behavior: 'smooth', block: 'start' });
    }, 50);
  }

  pricingCards.forEach(card => {
    card.addEventListener('click', (e) => {
      e.preventDefault();
      pricingCards.forEach(c => c.classList.remove('selected'));
      card.classList.add('selected');
      selectPlan(card.id);
    });
  });

  // 8. ANTI-TAMPERING & MUTATION OBSERVER (XSS & EXTENSION HIJACK PROTECTION)
  // Bu skript yuklab olish tugmalarini kuzatib turadi. Agar biron bir zararli kengaytma yoki XSS skript 
  // bot havolasini o'zgartirishga urinsa, zudlik bilan ulanishni to'xtatadi va qayta tiklaydi.
  const OFFICIAL_BOT_URL = "https://t.me/sergakaibot";
  const btnApk = document.getElementById('btnApkDownload');

  function enforceSecurity() {
    if (btnApk && btnApk.getAttribute('href') !== OFFICIAL_BOT_URL) {
      console.warn("⚠️ [SECURITY ALERT] Telegram Bot link modification detected! Restoring original.");
      btnApk.setAttribute('href', OFFICIAL_BOT_URL);
    }
  }

  // MutationObserver orqali DOM atributlarini real-vaqtda nazorat qilish
  const targetNode = document.getElementById('download');
  if (targetNode) {
    const observer = new MutationObserver((mutationsList) => {
      for (const mutation of mutationsList) {
        if (mutation.type === 'attributes') {
          enforceSecurity();
        }
      }
    });

    observer.observe(targetNode, {
      attributes: true,
      childList: true,
      subtree: true,
      attributeFilter: ['href']
    });
  }

  // Klik hodisalarni qo'shimcha himoya qilish
  const handleSecureRedirect = (e) => {
    enforceSecurity();
    const currentHref = e.currentTarget.getAttribute('href');
    if (currentHref !== OFFICIAL_BOT_URL) {
      e.preventDefault();
      alert("❌ XAVFSIZLIK OGOHLANTIRISHI: Havola buzilgan yoki o'zgartirilgan! Rasmiy botga yo'naltirilmoqda.");
      window.open(OFFICIAL_BOT_URL, '_blank');
    }
  };

  if (btnApk) btnApk.addEventListener('click', handleSecureRedirect);

  // Also protect the premium Telegram button
  const btnPremiumTg = document.getElementById('btnPremiumTelegram');
  if (btnPremiumTg) {
    btnPremiumTg.addEventListener('click', (e) => {
      const href = e.currentTarget.getAttribute('href');
      if (href !== OFFICIAL_BOT_URL) {
        e.preventDefault();
        alert("❌ XAVFSIZLIK OGOHLANTIRISHI: Premium bot havolasi buzilgan! Rasmiy botga yo'naltirilmoqda.");
        window.open(OFFICIAL_BOT_URL, '_blank');
      }
    });
  }

  // 10. CHECKOUT FORM SUBMISSION (API INTEGRATION)
  const mockupPaymentForm = document.getElementById('mockupPaymentForm');
  const checkoutContainer = document.getElementById('checkoutContainer');
  const paymentSuccess = document.getElementById('paymentSuccess');

  if (mockupPaymentForm) {
    mockupPaymentForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      
      const deviceIdInput = document.getElementById('deviceIdInput');
      if(!deviceIdInput || !deviceIdInput.value.trim()) {
        alert("Iltimos, Device ID ni kiriting!");
        return;
      }
      
      const planName = checkoutPlanName ? checkoutPlanName.textContent : '1 Yillik Reja';
      const duration = planName.includes('3') ? 3 : 12;

      // Show loading state on button
      const btn = mockupPaymentForm.querySelector('.btn-pay-now');
      const originalText = btn.innerHTML;
      btn.innerHTML = '⏳ To\'lov tekshirilmoqda...';
      btn.style.opacity = '0.7';
      btn.disabled = true;

      try {
        // Send request to backend API (Localhost for dev, Render production for live)
        const apiUrl = (window.location.hostname === "localhost" || window.location.hostname === "127.0.0.1")
          ? "http://localhost:8000/api/generate-license"
          : "https://sergak-bot.onrender.com/api/generate-license";
        const response = await fetch(apiUrl, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            device_id: deviceIdInput.value.trim(),
            duration_months: duration
          })
        });

        const data = await response.json();

        if (response.ok && data.license_key) {
          checkoutContainer.style.display = 'none';
          paymentSuccess.style.display = 'block';
          document.getElementById('licenseKeyTxt').textContent = data.license_key;
          paymentSuccess.scrollIntoView({ behavior: 'smooth', block: 'center' });
        } else {
          alert("Xatolik yuz berdi: " + (data.error || "Noma'lum xatolik"));
          btn.innerHTML = originalText;
          btn.style.opacity = '1';
          btn.disabled = false;
        }
      } catch (err) {
        console.error(err);
        alert("Serverga ulanishda xatolik! Bot ishlayotganiga ishonch hosil qiling.");
        btn.innerHTML = originalText;
        btn.style.opacity = '1';
        btn.disabled = false;
      }
    });
  }

  // 11. FAQ ACCORDION LOGIC
  const faqItems = document.querySelectorAll('.faq-item');
  faqItems.forEach(item => {
    const btn = item.querySelector('.faq-question');
    btn.addEventListener('click', () => {
      // Close other open items
      faqItems.forEach(otherItem => {
        if (otherItem !== item && otherItem.classList.contains('active')) {
          otherItem.classList.remove('active');
        }
      });
      // Toggle current item
      item.classList.toggle('active');
    });
  });

  // 11. COPY LICENSE KEY
  const licenseKeyBox = document.getElementById('licenseKeyBox');
  const licenseKeyTxt = document.getElementById('licenseKeyTxt');
  const copyToast = document.getElementById('copyToast');

  if (licenseKeyBox && licenseKeyTxt && copyToast) {
    licenseKeyBox.addEventListener('click', () => {
      const textToCopy = licenseKeyTxt.textContent; 
      navigator.clipboard.writeText(textToCopy).then(() => {
        const defaultText = copyToast.textContent;
        copyToast.textContent = "Litsenziya kaliti nusxalandi! ✅";
        copyToast.classList.add('show');
        setTimeout(() => {
          copyToast.classList.remove('show');
          setTimeout(() => { copyToast.textContent = defaultText; }, 500); // reset text after fade
        }, 3000);
      }).catch(err => {
        console.error('Nusxa olishda xatolik: ', err);
      });
    });
  }

  // Pre-load the first scan simulation as feedback for user
  setTimeout(() => {
    if (scanAppsBtn) scanAppsBtn.click();
  }, 1000);

});
