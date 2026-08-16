/// Nigerian states and LGAs used in student registration.
const List<String> states = [
  'Abia',
  'Adamawa',
  'Akwa Ibom',
  'Anambra',
  'Bauchi',
  'Bayelsa',
  'Benue',
  'Borno',
  'Cross River',
  'Delta',
  'Ebonyi',
  'Edo',
  'Ekiti',
  'Enugu',
  'Gombe',
  'Imo',
  'Jigawa',
  'Kaduna',
  'Kano',
  'Katsina',
  'Kebbi',
  'Kogi',
  'Kwara',
  'Lagos',
  'Nasarawa',
  'Niger',
  'Ogun',
  'Ondo',
  'Osun',
  'Oyo',
  'Plateau',
  'Rivers',
  'Sokoto',
  'Taraba',
  'Yobe',
  'Zamfara',
  'Abuja (FCT)',
];

const Map<String, List<String>> lgas = {
  'Kwara': [
    'Asa', 'Baruten', 'Edu', 'Ekiti', 'Ifelodun', 'Ilorin East', 'Ilorin South',
    'Ilorin West', 'Irepodun', 'Isin', 'Kaiama', 'Moro', 'Offa', 'Oke Ero',
    'Oyun', 'Pategi',
  ],
  'Lagos': [
    'Agege', 'Ajeromi-Ifelodun', 'Alimosho', 'Amuwo-Odofin', 'Apapa', 'Badagry',
    'Epe', 'Eti-Osa', 'Ibeju-Lekki', 'Ifako-Ijaiye', 'Ikeja', 'Ikorodu',
    'Kosofe', 'Lagos Island', 'Lagos Mainland', 'Mushin', 'Ojo', 'Oshodi-Isolo',
    'Shomolu', 'Surulere',
  ],
  'Abuja (FCT)': [
    'Abaji', 'Bwari', 'Gwagwalada', 'Kuje', 'Kwali', 'Municipal Area Council',
  ],
  'Ogun': [
    'Abeokuta North', 'Abeokuta South', 'Ado-Odo/Ota', 'Egbado North',
    'Egbado South', 'Ewekoro', 'Ifo', 'Ijebu East', 'Ijebu North',
    'Ijebu North East', 'Ijebu Ode', 'Ikenne', 'Imeko Afon', 'Ipokia',
    'Obafemi Owode', 'Odeda', 'Odogbolu', 'Ogun Waterside', 'Remo North',
    'Shagamu',
  ],
  'Oyo': [
    'Afijio', 'Akinyele', 'Atiba', 'Atisbo', 'Egbeda', 'Ibadan North',
    'Ibadan North-East', 'Ibadan North-West', 'Ibadan South-East',
    'Ibadan South-West', 'Ibarapa Central', 'Ibarapa East', 'Ibarapa North',
    'Ido', 'Irepo', 'Iseyin', 'Itesiwaju', 'Iwajowa', 'Kajola', 'Lagelu',
    'Ogbomosho North', 'Ogbomosho South', 'Ogo Oluwa', 'Olorunsogo', 'Oluyole',
    'Ona Ara', 'Orelope', 'Ori Ire', 'Oyo East', 'Oyo West', 'Saki East',
    'Saki West', 'Surulere',
  ],
  'Rivers': [
    'Abua/Odual', 'Ahoada East', 'Ahoada West', 'Akuku-Toru', 'Andoni',
    'Asari-Toru', 'Bonny', 'Degema', 'Eleme', 'Emohua', 'Etche', 'Gokana',
    'Ikwerre', 'Khana', 'Obio/Akpor', 'Ogba/Egbema/Ndoni', 'Ogu/Bolo',
    'Okrika', 'Omuma', 'Opobo/Nkoro', 'Oyigbo', 'Port Harcourt', 'Tai',
  ],
  'Kano': [
    'Ajingi', 'Albasu', 'Bagwai', 'Bebeji', 'Bichi', 'Bunkure', 'Dala',
    'Dambatta', 'Dawakin Kudu', 'Dawakin Tofa', 'Doguwa', 'Fagge', 'Gabasawa',
    'Garko', 'Garun Mallam', 'Gaya', 'Gezawa', 'Gwale', 'Gwarzo', 'Kabo',
    'Kano Municipal', 'Karaye', 'Kibiya', 'Kiru', 'Kumbotso', 'Kunchi',
    'Kura', 'Madobi', 'Makoda', 'Minjibir', 'Nasarawa', 'Rano', 'Rimin Gado',
    'Rogo', 'Shanono', 'Sumaila', 'Takai', 'Tarauni', 'Tofa', 'Tsanyawa',
    'Tudun Wada', 'Ungogo', 'Warawa', 'Wudil',
  ],
  'Kaduna': [
    'Birnin Gwari', 'Chikun', 'Giwa', 'Igabi', 'Ikara', 'Jaba', "Jema'a",
    'Kachia', 'Kaduna North', 'Kaduna South', 'Kagarko', 'Kajuru', 'Kaura',
    'Kauru', 'Kubau', 'Kudan', 'Lere', 'Makarfi', 'Sabon Gari', 'Sanga',
    'Soba', 'Zangon Kataf', 'Zaria',
  ],
  'Edo': [
    'Akoko-Edo', 'Egor', 'Esan Central', 'Esan North-East', 'Esan South-East',
    'Esan West', 'Etsako Central', 'Etsako East', 'Etsako West', 'Igueben',
    'Ikpoba Okha', 'Oredo', 'Orhionmwon', 'Ovia North-East', 'Ovia South-West',
    'Owan East', 'Owan West', 'Uhunmwonde',
  ],
  'Delta': [
    'Aniocha North', 'Aniocha South', 'Bomadi', 'Burutu', 'Ethiope East',
    'Ethiope West', 'Ika North East', 'Ika South', 'Isoko North', 'Isoko South',
    'Ndokwa East', 'Ndokwa West', 'Okpe', 'Oshimili North', 'Oshimili South',
    'Patani', 'Sapele', 'Udu', 'Ughelli North', 'Ughelli South', 'Ukwuani',
    'Uvwie', 'Warri North', 'Warri South', 'Warri South West',
  ],
  'Anambra': [
    'Aguata', 'Anambra East', 'Anambra West', 'Anaocha', 'Awka North',
    'Awka South', 'Ayamelum', 'Dunukofia', 'Ekwusigo', 'Idemili North',
    'Idemili South', 'Ihiala', 'Njikoka', 'Nnewi North', 'Nnewi South',
    'Ogbaru', 'Onitsha North', 'Onitsha South', 'Orumba North', 'Orumba South',
    'Oyi',
  ],
  'Enugu': [
    'Aninri', 'Awgu', 'Enugu East', 'Enugu North', 'Enugu South', 'Ezeagu',
    'Igbo Etiti', 'Igbo Eze North', 'Igbo Eze South', 'Isi Uzo', 'Nkanu East',
    'Nkanu West', 'Nsukka', 'Oji River', 'Udenu', 'Udi', 'Uzo Uwani',
  ],

  'Osun': [
    'Atakunmosa East', 'Atakunmosa West', 'Aiyedaade', 'Aiyedire', 'Boluwaduro',
    'Boripe', 'Ede North', 'Ede South', 'Egbedore', 'Ejigbo', 'Ife Central',
    'Ife East', 'Ife North', 'Ife South', 'Ifedayo', 'Ifelodun', 'Ila',
    'Ilesa East', 'Ilesa West', 'Irepodun', 'Irewole', 'Isokan', 'Iwo',
    'Obokun', 'Odo Otin', 'Ola Oluwa', 'Olorunda', 'Oriade', 'Orolu', 'Osogbo',
  ],
  'Ondo': [
    'Akoko North-East', 'Akoko North-West', 'Akoko South-East', 'Akoko South-West',
    'Akure North', 'Akure South', 'Ese Odo', 'Idanre', 'Ifedore', 'Ilaje',
    'Ile Oluji/Okeigbo', 'Irele', 'Odigbo', 'Okitipupa', 'Ondo East', 'Ondo West',
    'Ose', 'Owo',
  ],
  'Abia': [
    'Aba North', 'Aba South', 'Arochukwu', 'Bende', 'Ikwuano', 'Isiala Ngwa North',
    'Isiala Ngwa South', 'Isuikwuato', 'Obi Ngwa', 'Ohafia', 'Osisioma',
    'Ugwunagbo', 'Ukwa East', 'Ukwa West', 'Umuahia North', 'Umuahia South',
    'Umu Nneochi',
  ],
  'Imo': [
    'Aboh Mbaise', 'Ahiazu Mbaise', 'Ehime Mbano', 'Ezinihitte', 'Ideato North',
    'Ideato South', 'Ihitte/Uboma', 'Ikeduru', 'Isiala Mbano', 'Isu', 'Mbaitoli',
    'Ngor Okpala', 'Njaba', 'Nkwerre', 'Nwangele', 'Obowo', 'Oguta', 'Ohaji/Egbema',
    'Okigwe', 'Orlu', 'Orsu', 'Oru East', 'Oru West', 'Owerri Municipal',
    'Owerri North', 'Owerri West', 'Unuimo',
  ],
  'Plateau': [
    'Barkin Ladi', 'Bassa', 'Bokkos', 'Jos East', 'Jos North', 'Jos South',
    'Kanam', 'Kanke', 'Langtang North', 'Langtang South', 'Mangu', 'Mikang',
    'Pankshin', "Qua'an Pan", 'Riyom', 'Shendam', 'Wase',
  ],
  'Benue': [
    'Ado', 'Agatu', 'Apa', 'Buruku', 'Gboko', 'Guma', 'Gwer East', 'Gwer West',
    'Katsina-Ala', 'Konshisha', 'Kwande', 'Logo', 'Makurdi', 'Obi', 'Ogbadibo',
    'Ohimini', 'Oju', 'Okpokwu', 'Otukpo', 'Tarka', 'Ukum', 'Ushongo', 'Vandeikya',
  ],
  'Kogi': [
    'Adavi', 'Ajaokuta', 'Ankpa', 'Bassa', 'Dekina', 'Ibaji', 'Idah',
    'Igalamela Odolu', 'Ijumu', 'Kabba/Bunu', 'Kogi', 'Lokoja', 'Mopa Muro',
    'Ofu', 'Ogori/Magongo', 'Okehi', 'Okene', 'Olamaboro', 'Omala',
    'Yagba East', 'Yagba West',
  ],
};

/// Fallback LGAs when a state is not fully listed above
List<String> lgasFor(String state) {
  return lgas[state] ?? ['Municipal', 'Others'];
}

const List<String> nationalities = ['Nigeria'];
