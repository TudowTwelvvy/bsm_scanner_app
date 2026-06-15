using api.DTOs.User;
using api.Models;

namespace api.Mappers
{
    public class UserMapper
    {
        public static UserDto ToUserDto(AppUser user)
        {
            return new UserDto
            {
                Id = user.Id,
                Email = user.Email!,
                DisplayName = user.DisplayName,
                CreatedAt = user.CreatedAt,
                Roles = new List<string>()
            };
        }
    }
}