using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Interfaces;
using api.Mappers;
using Microsoft.AspNetCore.Mvc;

namespace api.Controllers
{
    [Route("api/user")]
    [ApiController]
    public class UserController : ControllerBase
    {
        private readonly IUserRespository _userRespository;
        public UserController(IUserRespository userRespository)
        {
            _userRespository = userRespository;
        }

        [HttpGet]
        public async Task<IActionResult> GetAllUsers()
        {
            var users = await _userRespository.GetAllUsersAsync();
            var userDtos = users.Select(UserMapper.ToUserDto).ToList(); 
            return Ok(userDtos);
        }

        [HttpGet("{id}")]
        public async Task<IActionResult> GetUserById(int id)
        {
            var user = await _userRespository.GetUserByIdAsync(id);
            if (user == null)
            {
                return NotFound();
            }
            return Ok(UserMapper.ToUserDto(user));
        
        }
    }
}