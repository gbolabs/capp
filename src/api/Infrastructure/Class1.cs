using Microsoft.EntityFrameworkCore;

namespace Infrastructure;

public class MyDbContext(DbContextOptions<MyDbContext> options) : DbContext(options)
{
    public DbSet<Product> Products { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer("YourConnectionStringHere");
        }
    }
}

public record Product(int Id, string Name);