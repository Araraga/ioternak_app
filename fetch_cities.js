const fs = require('fs');
const https = require('https');
https.get('https://raw.githubusercontent.com/mtegarsantosa/json-nama-daerah-indonesia/master/regions.json', (res) => {
  let data = '';
  res.on('data', chunk => data += chunk);
  res.on('end', () => {
    try {
      const json = JSON.parse(data);
      let allCities = [];
      for(let p of json) {
        if(p.kota) {
           allCities = allCities.concat(p.kota);
        }
      }
      let dartCode = 'class IndonesianCities {\n  static const List<String> cities = [\n';
      for(let c of allCities) {
        dartCode += '    \'' + c.replace(/'/g, "\\'") + '\',\n';
      }
      dartCode += '  ];\n}\n';
      fs.writeFileSync('lib/core/constants/indonesian_cities.dart', dartCode);
      console.log('Saved to indonesian_cities.dart with ' + allCities.length + ' cities.');
    } catch(e) { console.error(e); }
  });
});
