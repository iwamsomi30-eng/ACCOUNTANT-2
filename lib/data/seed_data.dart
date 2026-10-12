/// Kanda na Jumuiya zake (kutoka cole.xlsx) - Kanda 15.
class Kanda {
  final String name;
  final List<String> jumuiya;
  const Kanda(this.name, this.jumuiya);
}

const List<Kanda> kSeedKanda = [
  Kanda('Wat. Perpetua na Felista', [
    'Mt. Benedict',
    'Mt. Margreta Maria Alakoki',
    'Mt. Sirili',
    'Mt. Patric',
    'Mt. Ambrose',
    'Mt. Andrea',
  ]),
  Kanda('Mt. Bernadetha wa Lurdi', [
    'Mt. Yohane XXIII',
    'Mt. Yohane Paul II',
    'Mt. Theresia wa Calcuta',
    'Mt. Lucia',
    'Mt. Catherine wa Siena',
    'Wat. Petro na Paulo',
    'Mt. Pius X',
  ]),
  Kanda('Mt. Gasper De Buffalo', [
    'Mt. Pio',
    'Mt. Augustino',
    'Malaika Walinzi (Rafael)',
    'Mt. Boniface',
    'Mt. Kizito',
  ]),
  Kanda('Mt. Augustino wa Canteburry', [
    'Mt. Stefano',
    'Wat. Joakim na Anna',
    'Mt. Karoli Lwanga',
    'Mt. Anton wa Padua',
    'Mt. Gregory',
    'Mt. Inyasi wa Antiokia',
    'Mt. Getrude Bikira',
  ]),
  Kanda('Bikira Maria wa Rozali', [
    'Moyo Mtakatifu wa Yesu',
    'Mwili na Damu ya Yesu',
    'Malaika Wakuu',
    'Mt. John Bosco',
    'Mt. Francis wa Asizi',
    'Mt. Leo Mkuu',
    'Theresia wa Mtoto Yesu',
    'Mt. Francis Exavery',
    'Bikira Maria Mama wa Mungu',
  ]),
  Kanda('Mt. Maria Magdalena', [
    'Mt. Joseph Mfanyakazi',
    'Mt. Yohane Mbatizaji',
    'Mt. Philomena',
    'Mt. Coleta wa Jenti',
    'Mt. Mathayo',
    'Mt. Veronica',
  ]),
  Kanda('Bikira Maria wa Fatima', [
    'Mt. Maria Goreth',
    'Mt. Elizabeth wa Hungary',
    'Mt. Yuda Thadei',
    'Familia Takatifu',
    'Mt. Simforian',
    'Mt. Theresia wa Aviala',
    'Mt. Genoveva',
  ]),
  Kanda('Mt. Brigita', [
    'Mt. Monica',
    'Mt. Killian',
    'Mt. Charles Boromeo',
    'Mt. Laurent',
    'Mt. Getrude Comensoli',
    'Mt. Marko Mwinjili',
  ]),
  Kanda('Mt. Polycarp', [
    'Bikira Maria Mkingiwa Dhambi ya Asili',
    'Mt. Clara',
    'Mt. Maximilian Kolbe',
    'Mt. Cecilia',
  ]),
  Kanda('Mt. Martha', [
    'Mt. Antoni Rosmini',
    'Mt. Yohane Maria Vianey',
    'Mt. Jacob',
    'Mt. Thomas wa Akwino',
  ]),
  Kanda('Mwenyeheri Anuarite', [
    'Mt. Jacob',
    'Mt. Thomas wa Akwino',
    'Mt. Ritha',
    'Mt. Maria Faustina',
    'Mt. Josephine Bakhita',
    'Mt. Salome',
    'Mt. Dominiki',
    'Mt. Basili wa Kaesaria',
  ]),
  Kanda('Mt. Hellena', [
    'Mt. Luka',
    'Mt. Catherine wa Siena',
  ]),
  Kanda('Bikira Maria wa Huruma', [
    'Mt. Leo Mkuu',
    'Mt. Francis Exavery',
  ]),
  Kanda('Mt. Vicent De Paul', [
    'Mt. Stephano',
    'Mt. Gregory',
    'Wat. Joakim na Anna',
    'Mt. Geltrude Bikira',
  ]),
  Kanda('Mt. Joseph Mfanyakazi', [
    'Mt. Yohane Mbatizaji',
    'Mt. Martine De Pores',
    'Mt. Daniel',
    'Mt. Aloysius Gonzaga',
    'Mt. Barnabas Mtume',
  ]),
];

/// Majina ya zamani ya Kanda/Jumuiya (toleo la awali la programu) -> majina mapya.
/// Yanatumika kuhamisha rekodi zilizohifadhiwa ili zisipotee.
const Map<String, String> kLegacyKanda = {
  'Mt. Gasper De Buffalo': 'Mt. Gasper De Buffalo',
  'Mt Bernadeta Wa Lurdi': 'Mt. Bernadetha wa Lurdi',
  'Mt Hellena': 'Mt. Hellena',
  'Mt Vicent De Paul': 'Mt. Vicent De Paul',
  'Wat. Perpetua Na Felista': 'Wat. Perpetua na Felista',
};

/// Jumuiya za zamani -> mpya (ufunguo: 'Kanda ya zamani|Jumuiya ya zamani').
const Map<String, String> kLegacyJumuiya = {
  'Mt Benedict': 'Mt. Benedict',
  'Mt. Margareta Maria Alakoki': 'Mt. Margreta Maria Alakoki',
  'Mt Andrea': 'Mt. Andrea',
  'Mt. Ambrose': 'Mt. Ambrose',
  'Mt Pio': 'Mt. Pio',
  'Mt Agustino': 'Mt. Augustino',
  'Malaika Walinizi': 'Malaika Walinzi (Rafael)',
  'Mt Boniface': 'Mt. Boniface',
  'Mt Kizito': 'Mt. Kizito',
  'Mt Yohane XXX Papa': 'Mt. Yohane XXIII',
  'Mt Yohane Paulo II': 'Mt. Yohane Paul II',
  'Mt Pius X': 'Mt. Pius X',
  'Mt Teresa Wa Calcuta': 'Mt. Theresia wa Calcuta',
  'Mt Luka': 'Mt. Luka',
  'Mt Patrick': 'Mt. Patric',
  'Mt Lucia': 'Mt. Lucia',
  'Mt Catherine wa Siena': 'Mt. Catherine wa Siena',
  'Wt Petro Na Paulo': 'Wat. Petro na Paulo',
  'Mt Stephano': 'Mt. Stephano',
  'Mt Gregory': 'Mt. Gregory',
  'Mt Joakim na Anna': 'Wat. Joakim na Anna',
};
