//
component {

    /**
     * Try's to get a jwt token from the authorization header or the custom header
     * defined in the configuration or passed in by you. If it is a valid token and it decodes we will then
     * continue to validate the subject it represents.  Once those are satisfied, then it will
     * store it in the `prc` as `prc.jwt_token` and the payload as `prc.jwt_payload`.
     *
     * @token The token to parse and validate, if not passed we call the discoverToken() method for you.
     * @storeInContext By default, the token will be stored in the request context
     * @authenticate By default, the token will be authenticated, you can disable it and do manual authentication.
     *
     * @throws TokenExpiredException If the token has expired or no longer in the storage (invalidated)
     * @throws TokenInvalidException If the token doesn't verify decoding
     * @throws TokenNotFoundException If the token cannot be found in the headers
     *
     * @returns The payload for convenience
     */
    struct function parseToken(
        string token = discoverToken(),
        boolean storeInContext = true,
        boolean authenticate = true
    ) {
    }

}