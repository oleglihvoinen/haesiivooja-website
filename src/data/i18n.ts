import pagesFi from './pages.json';
import pagesEn from './pages.en.json';
import guidesFi from './guides.json';
import guidesEn from './guides.en.json';

// Explicit one-to-one translations. English URLs are meaningful English slugs;
// do not infer alternates by replacing /fi/ with /en/.
const pagePairs = pagesFi.map((fi, i) => ({ fi: `/${fi.slug}/`, en: `/en/${pagesEn[i].slug}/` }));
const guidePairs = guidesFi.map((fi, i) => ({ fi: `/oppaat/${fi.slug}/`, en: `/en/guides/${guidesEn[i].slug}/` }));
export const translatedPairs = [{fi: '/', en: '/en/'}, ...pagePairs, ...guidePairs];

export function alternateFor(current: string, language: 'fi' | 'en') {
  const match = translatedPairs.find(pair => pair.fi === current || pair.en === current);
  return match ? match[language] : null;
}

export const ui = {
  fi: {
    home: 'Etusivu', skip: 'Siirry sisältöön', navLabel: 'Päävalikko',
    search: 'AI-haku', searchAction: 'Avaa HaeSiivoojan AI-haku →',
    services: 'Kaikki siivouspalvelut', remember: 'Hyvä muistaa',
    rememberText: 'HaeSiivooja on digitaalinen alusta. Tarkista tekijän palvelun sisältö, hinta, ehdot ja saatavuus ennen tilausta.',
    pricingTips: 'Vinkit hinnan vertailuun →', faqEyebrow: 'Usein kysyttyä', faqTitle: 'Vastauksia kysymyksiin',
    ctaTitle: 'Etsimme siivoojia ympäri Suomen', ctaText: 'Rekisteröidy maksutta ja löydä siivousasiakkaita HaeSiivoojassa.', cta: 'Avaa sovellus Google Playssa →',
    guides: 'Oppaat', guide: 'Siivousopas', notice: 'Tämä on yleinen opas. Työn sisältö ja sovellettavat ehdot varmistetaan palveluntarjoajalta. Verotusasiat tarkistetaan Verohallinnolta.',
    allGuides: 'Kaikki oppaat', findCleaner: 'Etsi siivooja →', taxSource: 'Verohallinnon ajantasainen kotitalousvähennysohje',
    customers: 'Asiakkaille', forProviders: 'HaeSiivooja', forCleaners: 'Liity siivoojaksi', about: 'Tietoa meistä', contact: 'Yhteystiedot',
    compare: 'Hinnat ja vertailu', platformCopy: 'Siivouspalveluiden löytämiseen ja vertailuun suunniteltu digitaalinen alusta. Palvelun tarjonta riippuu alueesta ja ammattilaisista.',
    legalTerms: 'Käyttöehdot', legalPrivacy: 'Tietosuojakäytäntö', legalAccessibility: 'Saavutettavuusseloste',
    disclaimer: 'HaeSiivooja yhdistää asiakkaita ja palveluntarjoajia; palveluntarjoajat vastaavat omista palveluistaan.',
  },
  en: {
    home: 'Home', skip: 'Skip to content', navLabel: 'Main navigation',
    search: 'AI search', searchAction: 'Open HaeSiivooja AI search →',
    services: 'All cleaning services', remember: 'Before you book',
    rememberText: 'HaeSiivooja is a digital marketplace. Check the provider’s scope of work, price, terms and availability before booking.',
    pricingTips: 'Tips for comparing prices →', faqEyebrow: 'Frequently asked questions', faqTitle: 'Answers to common questions',
    ctaTitle: 'Cleaners wanted across Finland', ctaText: 'Register for free and find cleaning clients with HaeSiivooja.', cta: 'Open the Android app →',
    guides: 'Guides', guide: 'Cleaning guide', notice: 'This is general guidance. Confirm the scope and applicable terms with your provider. Check tax matters with the Finnish Tax Administration.',
    allGuides: 'All guides', findCleaner: 'Find a cleaner →', taxSource: 'Current household deduction guidance from Vero',
    customers: 'For customers', forProviders: 'HaeSiivooja', forCleaners: 'For cleaners', about: 'About us', contact: 'Contact',
    compare: 'Prices and comparisons', platformCopy: 'A digital marketplace designed to help customers discover and compare cleaning professionals in Finland. Availability depends on the area and providers.',
    legalTerms: 'Terms of service (Finnish page)', legalPrivacy: 'Privacy policy (Finnish page)', legalAccessibility: 'Accessibility statement (Finnish page)',
    disclaimer: 'HaeSiivooja connects customers and independent service providers; individual providers are responsible for their services.',
  },
} as const;
