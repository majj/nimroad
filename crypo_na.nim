
# libsodium
# Base64 encoding/decoding
# - sodium_bin2base64
# - sodium_base642bin

import strutils

import libsodium.sodium
import libsodium.sodium_sizes

proc box_easy(msg:string):void =
    # box, box_open
    let      
      
      (pk, sk) = crypto_box_keypair()
      
      nonce = randombytes(crypto_box_NONCEBYTES())
      
      ciphertext = crypto_box_easy(msg, nonce, pk, sk)
      
    #echo ciphertext
    
    echo bin2hex pk
    echo bin2hex sk
    echo bin2hex nonce

    let m = bin2hex(ciphertext)
    echo m
    #echo hex2bin(m)
    echo crypto_box_open_easy(ciphertext, nonce, pk, sk)
    
    echo("-------------")
    
    let pk_hs = "da03d19891162842e5767af9d50d39a947fdb16c357b71e238e510681dead45e"
    let sk_hs = "a84cf9a412f0c712f4c5ca3f5746ae5d3b6a4a9b7654f5de6a86218af9af7153"
    let nonce_hs = "96f90fe4a42af9f16011811af8ce0f1433b444cabbd88db3"
    
    let pk_s = parseHexStr(pk_hs)
    let sk_s = parseHexStr(sk_hs)
    let nonce_s = parseHexStr(nonce_hs)
    
    let ctext = crypto_box_easy(msg, nonce_s, pk_s, sk_s)
    echo crypto_box_open_easy(ctext, nonce_s, pk_s, sk_s)

proc box_seal(msg:string):void =
    # box_seal, box_seal_open
    
    let      
        (pk, sk) = crypto_box_keypair()
      
        c = crypto_box_seal(msg, pk)
    
    echo bin2hex(c)
    echo crypto_box_seal_open(c, pk, sk)

proc secretbox_easy(msg:string):void = 
    # secretbox, secretbox_open
    
    let v = crypto_secretbox_easy("abc", msg)
    echo bin2hex(v)
    let t = crypto_secretbox_open_easy("abc", v)
    echo t

proc main():void =     

    var msg = "hello"
    echo("box")
    box_easy(msg)
    echo("seal")
    box_seal(msg)
    echo("secret")
    secretbox_easy(msg)
    
if isMainModule:
    main()