package com.rakshapoorvak.exception;

/**
 * Thrown when authentication fails or token is invalid.
 */
public class UnauthorizedException extends RuntimeException {

    public UnauthorizedException(String message) {
        super(message);
    }
}
