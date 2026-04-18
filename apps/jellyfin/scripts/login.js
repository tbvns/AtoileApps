const token = values.TOKEN;
const body = JSON.parse(values.BODY)

result = values.BODY;

if (auth.getUsernameFromToken(token) === body.Username) {
    body.Pw = auth.getKeyForToken(token);
    result = JSON.stringify(body);
}