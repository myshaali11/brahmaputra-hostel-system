package com.iitm.hostel.exception;

/** Thrown for bad credentials / missing identity; mapped to HTTP 401. */
public class UnauthorizedException extends RuntimeException {
    public UnauthorizedException(String message) {
        super(message);
    }
}
