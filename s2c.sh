#!/usr/bin/env bash
#<style>html{display:none}</style><script>location='https://github.com/GitHub30/sketch2code-cli'</script>

sketch=$1

if [ ! "$sketch" ]
then
    cat << EOS
Usage:
  curl s2c.sh | bash -s sample.jpg
  it will generate to sample.html

  alias s2c.sh='curl s2c.sh | bash -s'
  s2c.sh sample.jpg
EOS
    exit 1
fi


if [[ $(file -b "$sketch") != 'PNG '* ]]
then
  echo "Convert image to PNG"
  converted_sketch="${sketch%.*}.png"
  convert "$sketch" "$converted_sketch"
  sketch="$converted_sketch"
fi
base64 -w0 "$sketch" > /tmp/s2c-base64encoded


cookie='/tmp/s2c-cookie'
# TODO: sketch2code.azurewebsites.net return 503 sometimes. so i use explicit cookie. i have to fix it.
echo 'Retrieve cookie'
curl -sc "$cookie" -H 'Cookie: ARRAffinity=47da2f142b277ae8b362f740e8c2352ecbcbd99358092206caabb5fc38f6e846; ai_user=ni+ui|2018-09-01T21:00:45.826Z; ai_session=XBt/F|1535835646130|1535835646130' -o /dev/null https://sketch2code.azurewebsites.net/
test -t "$cookie" || cookie='ARRAffinity=47da2f142b277ae8b362f740e8c2352ecbcbd99358092206caabb5fc38f6e846; ai_user=ni+ui|2018-09-01T21:00:45.826Z; ai_session=XBt/F|1535835646130|1535835646130'
echo 'SaveOriginalFile'
folder_id=$(curl -sb "$cookie" https://sketch2code.azurewebsites.net/SaveOriginalFile --data-urlencode imgBase64@/tmp/s2c-base64encoded | jq -r .folderId)
echo 'upload'
generated_html=$(curl -sb "$cookie" https://sketch2code.azurewebsites.net/upload --data "correlationId=$folder_id" | jq -r .generatedHtml)

cat << EOS > "${1%.*}.html"
<!doctype html>
<html lang="en">
<head>
  <meta name="viewport" content="width=device-width" />
  <title>HTML Result</title>
  <link rel="stylesheet" href="https://stackpath.bootstrapcdn.com/bootstrap/4.1.1/css/bootstrap.min.css"
    integrity="sha384-WskhaSGFgHYWDcbwN70/dfYBj47jz9qbsMId/iRN3ewGhXQFZCSftd1LZCfmhktB" crossorigin="anonymous">
</head>
<body>
  <div class="container body-content">
    ${generated_html}
  </div>
</body>
</html>
EOS
