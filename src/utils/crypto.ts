import CryptoJS from 'crypto-js';

const SECRET_KEY = process.env.CRYPTO_SECRET_KEY || 'tu_clave_secreta'; // Usar variables de entorno

export const encryptData = (data: string): string => {
  return CryptoJS.AES.encrypt(data, SECRET_KEY).toString();
};

export const decryptData = (encryptedData: string): string => {
  const bytes = CryptoJS.AES.decrypt(encryptedData, SECRET_KEY);
  return bytes.toString(CryptoJS.enc.Utf8);
};