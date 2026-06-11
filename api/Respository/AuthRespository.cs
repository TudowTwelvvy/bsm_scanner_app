using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using api.Data;
using api.Interfaces;

namespace api.Respository
{
    public class AuthRespository: IAuthRespository
    {
        private readonly ApplicationDBContext _context;
        public AuthRespository(ApplicationDBContext context)
        {
            _context = context;
            
        }


        public Task<string> LoginAsync(string email, string password)
        {
            throw new NotImplementedException();
        }

        public Task<string> RegisterAsync(string email, string password, string displayName)
        {
            throw new NotImplementedException();
        }
        
    }
}