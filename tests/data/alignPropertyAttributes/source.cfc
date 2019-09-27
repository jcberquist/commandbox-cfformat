//
property name="jwt" inject="provider:JWTService@jwt";
property name="wirebox" inject="wirebox";
property name="settings" inject="coldbox:moduleSettings:cbSecurity";
// test comment here
property name="interceptorService" inject="coldbox:interceptorService";

property name="requestService" inject="coldbox:requestService";
property name="log" inject="logbox:logger:{this}";
