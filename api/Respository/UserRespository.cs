using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.Interfaces;
using api.Models;
using Microsoft.EntityFrameworkCore;

namespace api.Respository
{
    public class UserRespository : IUserRespository
    {
        /*private readonly ApplicationDBContext _context;
        public UserRespository(ApplicationDBContext context)
        {
            _context = context;
        }


        public async Task<List<User>> GetAllUsersAsync()
        {

            return await _context.Users.Include(u => u.Products).ToListAsync();
        }

        public async Task<User?> GetUserByIdAsync(int id)
        {
            return await _context.Users.Include(u => u.Products).FirstOrDefaultAsync(u => u.Id == id);
        }*/
    }
}
