package com.rakshapoorvak.exception;

/**
 * Thrown when user lacks permission for the requested action.
 */
public class ForbiddenException extends RuntimeException {

    public ForbiddenException(String message) {
        super(message);
    }
}
