var http = require('http');

http.createServer(function (req, res) {

  res.writeHead(200, {'Content-Type': 'text/html'});
  res.end('<h1>Prova OK!</h1>\n');

}).listen(process.argv[2]);
