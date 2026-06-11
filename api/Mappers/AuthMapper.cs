using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.Auth;
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

        public static User ToUser(RegisterReqDto registerReqDto)
        {
            return new User
            {
                Email = registerReqDto.Email,
                PasswordHash = registerReqDto.Password,
                DisplayName = registerReqDto.DisplayName
            };
        }

        public static User ToUser(LoginRequest loginReqDto)
        {
            return new User
            {
                Email = loginReqDto.Email,
                PasswordHash = loginReqDto.Password
            };
        }
    }   
}