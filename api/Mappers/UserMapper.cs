using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.DTOs.User;
using api.Models;

namespace api.Mappers
{
    public class UserMapper
    {
        public static UserDto ToUserDto(User user)
        {
            return new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                DisplayName = user.DisplayName,
                CreatedAt = user.CreatedAt,
                Products = user.Products.Select(p => ProductMappers.ToProductDto(p)).ToList()
            };
        }

        public static User ToUser(UserDto userDto)
        {
            return new User
            {
                Id = userDto.Id,
                Email = userDto.Email,
                DisplayName = userDto.DisplayName,
                CreatedAt = userDto.CreatedAt
            };
        }
    }
}