using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.Auth;
using api.DTOs.User;
using api.Models;

namespace api.Mappers
{
    public class AuthMapper
    {
        public static AuthResDto ToAuthResDto(string token, User user)
        {
            return new AuthResDto
            {
                Token = token,
                User = UserMapper.ToUserDto(user)
            };
        }

        public static AppUser ToUser(RegisterReqDto registerReqDto)
        {
            return new AppUser
            {
                Email = registerReqDto.Email,
                PasswordHash = registerReqDto.Password,
                DisplayName = registerReqDto.DisplayName,
                EmailConfirmed = true //skip confirmation for now
            };
        }

        public static AppUser ToUser(LoginRequest loginReqDto)
        {
            return new AppUser
            {
                Email = loginReqDto.Email,
                PasswordHash = loginReqDto.Password
            };
        }
    }   
}