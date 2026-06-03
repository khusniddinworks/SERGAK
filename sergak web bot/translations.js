const translations = {
  uz: {
    nav_features: "Imkoniyatlar",
    nav_pricing: "Narxlar",
    nav_demo: "Demo Simulator",
    nav_tech: "Texnologiya",
    nav_download: "Yuklab olish",
    testi_label: "MIJOZLAR FIKRI",
    testi_title: "Foydalanuvchilar nima deydi?",
    testi_1: "\"Juda zo'r himoya tizimi! Oflayn ishlashi eng katta plyus. Internet bo'lmaganda ham virusli SMSlarni blokladi.\"",
    testi_2: "\"Kiber-maslahatchi xuddi haqiqiy ekspertdek. Menga yuborilgan soxta linkni bir soniyada fosh qildi.\"",
    testi_3: "\"1 yillik tarifni oldim va xotirjamman. Bank ilovalarim xavfsizligidan endi xavotir olmayman.\"",
    faq_label: "SAVOLLAR",
    faq_title: "Ko'p beriladigan savollar",
    faq_q1: "To'lov ma'lumotlarim xavfsizmi?",
    faq_a1: "Ha, barcha to'lovlar AES-256 bilan shifrlangan. Biz sizning karta ma'lumotlaringizni serverlarimizda saqlamaymiz.",
    faq_q2: "Litsenziya qanday ishlaydi?",
    faq_a2: "Saytdan to'lov qilganingizdan so'ng, sizga maxsus kod beriladi. Uni ilovadagi \"Premium\" bo'limiga kiritsangiz kifoya.",
    faq_q3: "Dastur internetni ko'p yeydimi?",
    faq_a3: "Yo'q, dastur 100% oflayn rejimda ishlaydi. Faqat litsenziyani tasdiqlash uchun ilk bor qisqa muddatli internet talab qilinadi.",
    footer_legal: "Huquqiy",
    footer_privacy: "Maxfiylik Siyosati",
    footer_terms: "Foydalanish shartlari",
    footer_team: "Jamoa",
    footer_initiators: "Tashabbuskorlar",
    privacy_title: "Maxfiylik Siyosati",
    terms_title: "Foydalanish shartlari"
  },
  ru: {
    nav_features: "Возможности",
    nav_pricing: "Цены",
    nav_demo: "Демо-симулятор",
    nav_tech: "Технология",
    nav_download: "Скачать",
    testi_label: "ОТЗЫВЫ КЛИЕНТОВ",
    testi_title: "Что говорят пользователи?",
    testi_1: "\"Отличная система защиты! Работа офлайн — огромный плюс. Блокирует вирусные SMS даже без интернета.\"",
    testi_2: "\"Кибер-советник работает как настоящий эксперт. Распознал поддельную ссылку за секунду.\"",
    testi_3: "\"Купил тариф на 1 год и спокоен. Больше не беспокоюсь о безопасности своих банковских приложений.\"",
    faq_label: "ВОПРОСЫ",
    faq_title: "Часто задаваемые вопросы",
    faq_q1: "Мои платежные данные в безопасности?",
    faq_a1: "Да, все платежи защищены шифрованием AES-256. Мы не храним данные ваших карт на наших серверах.",
    faq_q2: "Как работает лицензия?",
    faq_a2: "После оплаты на сайте вы получите специальный код. Просто введите его в разделе «Премиум» в приложении.",
    faq_q3: "Программа потребляет много интернета?",
    faq_a3: "Нет, программа работает 100% в автономном режиме. Кратковременный доступ к интернету нужен только при первой проверке лицензии.",
    footer_legal: "Правовая информация",
    footer_privacy: "Политика конфиденциальности",
    footer_terms: "Условия использования",
    footer_team: "Команда",
    footer_initiators: "Инициаторы",
    privacy_title: "Политика конфиденциальности",
    terms_title: "Условия использования"
  }
};

document.addEventListener("DOMContentLoaded", () => {
  const btnUz = document.getElementById("langUz");
  const btnRu = document.getElementById("langRu");
  if (!btnUz || !btnRu) return;

  function setLanguage(lang) {
    localStorage.setItem("sergak_lang", lang);
    if (lang === "uz") {
      btnUz.classList.add("active");
      btnRu.classList.remove("active");
    } else {
      btnRu.classList.add("active");
      btnUz.classList.remove("active");
    }

    document.querySelectorAll("[data-i18n]").forEach(el => {
      const key = el.getAttribute("data-i18n");
      if (translations[lang] && translations[lang][key]) {
        el.textContent = translations[lang][key];
      }
    });
  }

  btnUz.addEventListener("click", () => setLanguage("uz"));
  btnRu.addEventListener("click", () => setLanguage("ru"));

  // Check saved language
  const savedLang = localStorage.getItem("sergak_lang") || "uz";
  setLanguage(savedLang);
});
