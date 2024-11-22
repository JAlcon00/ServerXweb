import rateLimit from 'express-rate-limit';

export const loginLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutos
    max: 5, // 5 intentos máximos
    message: { error: 'Demasiados intentos de login. Por favor, intente más tarde.' }
});