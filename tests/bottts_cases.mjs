// Additional compatibility cases retained from the first release.
export default function casesForBottts(definition) {
const cases = ['', 'alice', 'Bob', 'Ada 🤖', '日本語', 'é', 'e\u0301', '𐀀', '􏿿'].map(seed => ({seed}));
for (const [name, component] of Object.entries(definition.components)) {
  for (const variant of Object.keys(component.variants)) {
    cases.push({seed: 'every-variant', [`${name}Variant`]: variant, textureProbability: 100});
  }
}
cases.push(
  {seed:'editor', size:256, title:'<Robot & "friend">', eyesVariant:'happy', baseColor:'abc', backgroundColor:'1234'},
  {seed:'transform', flip:'both', rotate:32.12345, scale:0.75, translateX:12.5, translateY:-8, borderRadius:25, backgroundColor:'ffffff'},
  {seed:'ranges', rotate:[-19,21], scale:[0.3,1.5], translateX:[20,-20], borderRadius:[8,20]},
  {seed:'single', scale:[0.8], rotate:[], eyesVariant:['happy','happy','dizzy'], baseColor:['abc','aabbcc','000000']},
  {seed:'weights', eyesVariant:{happy:3,dizzy:0,hearts:9}, mouthVariant:{bite:0,diagram:0}},
  {seed:'hidden', eyesProbability:0, headProbability:0, sidesProbability:0, topProbability:0, mouthProbability:0},
  {seed:'empty', eyesVariant:[], textureVariant:[], baseColor:[], backgroundColor:[]},
  {seed:'avoid', baseColor:['ffffff','000000'], backgroundColor:'ffffff'},
  {seed:'fallback', baseColor:['ffffff'], backgroundColor:'ffffff'},
  {seed:'alpha', baseColor:['abcdef00','123456ff'], backgroundColor:'abcdef80'},
);
for (let i = 0; i < 80; i++) cases.push({seed:`generated-${i}`, textureProbability:i % 101, eyesProbability:33.5});

return cases;
}
