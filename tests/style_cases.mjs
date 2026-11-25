export default function casesForStyle(definition) {
  const cases = ['', 'alice', 'Bob', 'Ada 🤖', '日本語', 'é', 'e\u0301', '𐀀', '􏿿',
    "O'Connor", 'ß Müller', '1@Ada Lovelace', 'a@\nb', 'Αλέξανδρος Παπαδόπουλος',
    'अर्जुन शर्मा', '𐐨𐐩', '👩‍💻', 'Łukasz Żółć'].map(seed => ({seed}));
  const components = Object.entries(definition.components || {}).filter(([,c]) => !c.extends);
  const visible = Object.fromEntries(components.map(([name]) => [`${name}Probability`,100]));
  for (const [name, component] of components) {
    for (const variant of Object.keys(component.variants)) {
      cases.push({seed:'every-variant', ...visible, [`${name}Variant`]:variant});
    }
    const names = Object.keys(component.variants);
    cases.push({seed:'choices', [`${name}Variant`]:[names.at(-1), names[0], names[0]]});
    cases.push({seed:'weights', [`${name}Variant`]:Object.fromEntries(names.map((n,i) => [n,i%3]))});
    cases.push({seed:'hidden', [`${name}Probability`]:0});
  }
  for (const name of new Set(['background',...Object.keys(definition.colors || {})])) {
    cases.push({seed:'palette', [`${name}Color`]:['#ffffffff','#111','#12345680','#abc','#aabbcc']});
    cases.push({seed:'transparent', [`${name}Color`]:[]});
  }
  cases.push(
    {seed:'transform', flip:'both', rotate:32.12345, scale:0.75, translateX:12.5, translateY:-8, borderRadius:25, backgroundColor:'ffffff'},
    {seed:'ranges', rotate:[-19,21], scale:[0.3,1.5], translateX:[20,-20], borderRadius:[8,20]},
    {seed:'title', title:'<Avatar & "friend">', size:256},
    {seed:'Ada Lovelace', fontFamily:'Arial, sans-serif', fontWeight:700},
  );
  for (let i=0;i<20;i++) cases.push({seed:`generated-${i}`});
  return cases;
}
