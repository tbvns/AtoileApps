const token = values.TOKEN;
const body = JSON.parse(values.BODY)

result = values.BODY;

if (token) {
    if (auth.getUsernameFromToken(token) === body.Username) {
        body.Pw = auth.getKeyForToken(token);
        result = JSON.stringify(body);
    }
} else {
    if (auth.validateCredentials(body.Username, body.Pw)) {
        body.Pw = auth.getKeyForUsername(body.Username);
        result = JSON.stringify(body);
    }
}